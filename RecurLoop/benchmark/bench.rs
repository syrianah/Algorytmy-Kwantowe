// Benchmark symulatora wektora stanu w Rust.
// Ten sam algorytm co quantum.rl: pętla po wszystkich indeksach amplitud
// i sprawdzanie bitów. Dwa warianty sprawdzania bitów:
//   div - dzielenie i modulo jak w RecurLoop, który nie ma operatorów bitowych
//   bit - operatory bitowe & i <<
//
// Kompilacja:  rustc -C opt-level=3 -C target-cpu=native bench.rs -o bench_rs
// Użycie:      ./bench_rs (div|bit) teleport N
//              ./bench_rs (div|bit) layers QUBITS DEPTH

use std::env;
use std::time::Instant;

struct Rng(u64);

impl Rng {
    // xorshift64*, wynik w [0, 1)
    fn next(&mut self) -> f64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        let v = self.0.wrapping_mul(0x2545F4914F6CDD1D);
        (v >> 11) as f64 / (1u64 << 53) as f64
    }
}

struct State {
    n: i64,
    size: i64,
    re: Vec<f64>,
    im: Vec<f64>,
    theta: Vec<f64>,
    phi: Vec<f64>,
    bitwise: bool,
}

// Potęga dwójki liczona pętlą, jak w quantum.rl. Kompilator nie wie wtedy,
// że dzielnik jest potęgą dwójki, więc wariant div naprawdę dzieli.
#[inline(never)]
fn pow2(k: i64) -> i64 {
    let mut r = 1i64;
    let mut i = 0;
    while i < k {
        r = std::hint::black_box(r * 2);
        i += 1;
    }
    r
}

impl State {
    fn new(bitwise: bool) -> State {
        State { n: 0, size: 1, re: vec![1.0], im: vec![0.0], theta: vec![], phi: vec![], bitwise }
    }

    fn alloc(&mut self) -> i64 {
        let new_size = (self.size * 2) as usize;
        self.re.resize(new_size, 0.0);
        self.im.resize(new_size, 0.0);
        self.theta.push(0.0);
        self.phi.push(0.0);
        self.n += 1;
        self.size = new_size as i64;
        self.n - 1
    }

    // U = [[a, b], [c, d]], liczby zespolone jako pary (re, im)
    fn apply(&mut self, c1: i64, c2: i64, t: i64, u: [f64; 8]) {
        let [ar, ai, br, bi, cr, ci, dr, di] = u;
        let mt = pow2(t);
        let m1 = if c1 >= 0 { pow2(c1) } else { 0 };
        let m2 = if c2 >= 0 { pow2(c2) } else { 0 };
        let re = &mut self.re;
        let im = &mut self.im;
        let mut i = 0i64;
        while i < self.size {
            let active = if self.bitwise {
                (i & mt) == 0 && (m1 == 0 || (i & m1) != 0) && (m2 == 0 || (i & m2) != 0)
            } else {
                i / mt % 2 == 0 && (m1 == 0 || i / m1 % 2 == 1) && (m2 == 0 || i / m2 % 2 == 1)
            };
            if active {
                let iu = i as usize;
                let j = (i + mt) as usize;
                let (xr, xi, yr, yi) = (re[iu], im[iu], re[j], im[j]);
                re[iu] = ar * xr - ai * xi + br * yr - bi * yi;
                im[iu] = ar * xi + ai * xr + br * yi + bi * yr;
                re[j] = cr * xr - ci * xi + dr * yr - di * yi;
                im[j] = cr * xi + ci * xr + dr * yi + di * yr;
            }
            i += 1;
        }
    }

    fn bit(&self, i: i64, m: i64) -> i64 {
        if self.bitwise { ((i & m) != 0) as i64 } else { i / m % 2 }
    }

    fn h(&mut self, t: i64) {
        let k = 1.0 / 2f64.sqrt();
        self.apply(-1, -1, t, [k, 0.0, k, 0.0, k, 0.0, -k, 0.0]);
    }
    fn x(&mut self, c1: i64, t: i64) {
        self.apply(c1, -1, t, [0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0]);
    }
    fn z(&mut self, t: i64) {
        self.apply(-1, -1, t, [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0]);
    }
    fn phase(&mut self, t: i64, a: f64) {
        self.apply(-1, -1, t, [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, a.cos(), a.sin()]);
    }
    fn ry(&mut self, t: i64, a: f64) {
        let (c, s) = ((a / 2.0).cos(), (a / 2.0).sin());
        self.apply(-1, -1, t, [c, 0.0, -s, 0.0, s, 0.0, c, 0.0]);
    }

    fn prob_one(&self, t: i64) -> f64 {
        let m = pow2(t);
        let mut p = 0.0;
        for i in 0..self.size {
            if self.bit(i, m) == 1 {
                let iu = i as usize;
                p += self.re[iu] * self.re[iu] + self.im[iu] * self.im[iu];
            }
        }
        p
    }

    fn measure(&mut self, t: i64, rng: &mut Rng) -> i64 {
        let p1 = self.prob_one(t);
        let outcome = if rng.next() < p1 { 1 } else { 0 };
        let p = if outcome == 1 { p1 } else { 1.0 - p1 };
        let norm = 1.0 / p.sqrt();
        let m = pow2(t);
        for i in 0..self.size {
            let iu = i as usize;
            if self.bit(i, m) == outcome {
                self.re[iu] *= norm;
                self.im[iu] *= norm;
            } else {
                self.re[iu] = 0.0;
                self.im[iu] = 0.0;
            }
        }
        outcome
    }

    fn prepare_random(&mut self, t: i64, rng: &mut Rng) {
        let theta = (1.0 - 2.0 * rng.next()).acos();
        let phi = 2.0 * std::f64::consts::PI * rng.next();
        self.ry(t, theta);
        self.phase(t, phi);
        self.theta[t as usize] = theta;
        self.phi[t as usize] = phi;
    }

    fn fidelity(&mut self, t: i64, r: i64) -> f64 {
        let (theta, phi) = (self.theta[r as usize], self.phi[r as usize]);
        self.phase(t, -phi);
        self.ry(t, -theta);
        let f = 1.0 - self.prob_one(t);
        self.ry(t, theta);
        self.phase(t, phi);
        f
    }
}

fn teleport(bitwise: bool, rng: &mut Rng) -> i64 {
    let mut s = State::new(bitwise);
    let psi = s.alloc();
    let alice = s.alloc();
    let bob = s.alloc();
    s.prepare_random(psi, rng);
    s.h(alice);
    s.x(alice, bob);
    s.x(psi, alice);
    s.h(psi);
    let m1 = s.measure(psi, rng);
    let m2 = s.measure(alice, rng);
    if m2 == 1 { s.x(-1, bob); }
    if m1 == 1 { s.z(bob); }
    let f = s.fidelity(bob, psi);
    if (1.0 - f).abs() >= 1e-9 {
        panic!("teleportacja nieudana, wierność {}", f);
    }
    m1 * 2 + m2
}

// Warstwa: H i RY(0.1 + 0.05 q) na każdym kubicie, potem łańcuch CNOT q -> q+1.
// Wynik: norma, P(q0 = 1) i ostatnia amplituda jako suma kontrolna.
fn layers(bitwise: bool, n: i64, depth: i64) -> (f64, f64, f64, f64) {
    let mut s = State::new(bitwise);
    for _ in 0..n { s.alloc(); }
    for _ in 0..depth {
        for q in 0..n {
            s.h(q);
            s.ry(q, 0.1 + 0.05 * q as f64);
        }
        for q in 0..n - 1 { s.x(q, q + 1); }
    }
    let norm: f64 = (0..s.size as usize).map(|i| s.re[i] * s.re[i] + s.im[i] * s.im[i]).sum();
    let last = (s.size - 1) as usize;
    (norm, s.prob_one(0), s.re[last], s.im[last])
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let bitwise = args[1] == "bit";
    let start = Instant::now();
    match args[2].as_str() {
        "teleport" => {
            let n: i64 = args[3].parse().unwrap();
            let mut rng = Rng(0x9E3779B97F4A7C15);
            let mut counts = [0i64; 4];
            for _ in 0..n { counts[teleport(bitwise, &mut rng) as usize] += 1; }
            let ms = start.elapsed().as_secs_f64() * 1000.0;
            println!("teleport n={} wyniki={:?} czas_ms={:.1}", n, counts, ms);
        }
        "layers" => {
            let q: i64 = args[3].parse().unwrap();
            let d: i64 = args[4].parse().unwrap();
            let (norm, p0, ar, ai) = layers(bitwise, q, d);
            let ms = start.elapsed().as_secs_f64() * 1000.0;
            println!("layers q={} d={} norma={:.12} p0={:.12} amp=({:.12e}, {:.12e}) czas_ms={:.1}", q, d, norm, p0, ar, ai, ms);
        }
        _ => panic!("nieznany test"),
    }
}
