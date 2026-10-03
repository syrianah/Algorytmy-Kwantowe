// Benchmark of the quantum.rl library. The same algorithm as bench.rs and bench.py.
//
// Usage from the benchmark directory:
//   recurloop --file bench.rl
// The test parameters are set at the bottom of the file.

include "../quantum.rl"

extern clock_gettime(clock:i64, out:u8*) -> i64 abi sysv-amd64

record BenchTime {
    sec:i64
    nsec:i64
}

fn now_ns() -> i64 {
    var t:BenchTime* = cast(BenchTime*, malloc(16))
    clock_gettime(1, cast(u8*, t))
    var result = t.sec * 1000000000 + t.nsec
    free(cast(u8*, t))
    return result
}

circuit teleport {
    qubit psi
    qubit alice
    qubit bob
    prepare psi random
    H alice
    CNOT alice, bob
    CNOT psi, alice
    H psi
    measure psi -> m1
    measure alice -> m2
    if m2 == 1 {
        X bob
    }
    if m1 == 1 {
        Z bob
    }
    expect bob == psi
    return m1 * 2 + m2
}

// A layer: H and RY(0.1 + 0.05 q) on every qubit, then a chain of CNOT q -> q+1.
circuit layers(n:i64, depth:i64) {
    var k = 0
    while k < n {
        Quantum:alloc(qs, "q")
        k += 1
    }
    var d = 0
    while d < depth {
        var q = 0
        while q < n {
            H q
            RY(0.1 + 0.05 * cast(f64, q)) q
            q += 1
        }
        q = 0
        while q < n - 1 {
            CNOT q, q + 1
            q += 1
        }
        d += 1
    }
    var s:Quantum:State* = cast(Quantum:State*, qs)
    var norm = 0.0
    var i = 0
    while i < s.size {
        norm = norm + s.re[i] * s.re[i] + s.im[i] * s.im[i]
        i += 1
    }
    var last = s.size - 1
    var p0 = Quantum:prob_one(qs, 0)
    printf("layers q=%lld d=%lld norm=%.12f p0=%.12f amp=(%.12e, %.12e)", n, depth, norm, p0, s.re[last], s.im[last])
    return 0
}

experiment bench_teleport(count:i64) {
    var start = now_ns()
    var c00 = 0
    var c01 = 0
    var c10 = 0
    var c11 = 0
    var i = 0
    while i < count {
        var w = teleport()
        if w == 0 { c00 += 1 }
        if w == 1 { c01 += 1 }
        if w == 2 { c10 += 1 }
        if w == 3 { c11 += 1 }
        i += 1
    }
    var ms = cast(f64, now_ns() - start) / 1000000.0
    printf("teleport n=%lld counts=[%lld, %lld, %lld, %lld] time_ms=%.1f\n", count, c00, c01, c10, c11, ms)
    return 0
}

experiment bench_layers(n:i64, depth:i64) {
    var start = now_ns()
    layers(n, depth)
    var ms = cast(f64, now_ns() - start) / 1000000.0
    printf(" time_ms=%.1f\n", ms)
    return 0
}

bench_teleport(100000)
bench_layers(16, 5)
bench_layers(20, 5)
