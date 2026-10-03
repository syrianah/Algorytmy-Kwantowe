// =============================================================================
// Quantum: biblioteka do symulacji obwodów kwantowych w RecurLoop
//
// Silnik przechowuje wektor stanu (2^n amplitud zespolonych) i aplikuje bramki
// w miejscu, zmieniając tylko pary amplitud, których dotyczy bramka. Nie buduje
// pełnych macierzy 2^n x 2^n jak iloczyn Kroneckera.
//
// Kubit o indeksie k odpowiada bitowi k indeksu amplitudy. Nowe kubity
// dokładane są w stanie |0> jako kolejne, wyższe bity.
//
// Użycie:
//   include "quantum.rl"
//
//   circuit bell {
//       qubit a
//       qubit b
//       H a
//       CNOT a, b
//       measure a -> wynik
//       show state
//       return wynik
//   }
//
//   bell()
//
// Pełny opis składni jest w README.md.
// =============================================================================

link shared "c"
link shared "m"

extern malloc(size:u64) -> u8* abi sysv-amd64
extern realloc(pointer:u8*, size:u64) -> u8* abi sysv-amd64
extern free(pointer:u8*) -> void abi sysv-amd64
extern strdup(text:u8*) -> u8* abi sysv-amd64
extern printf(format:u8*, ...) -> i64 abi sysv-amd64
extern time(out:u8*) -> i64 abi sysv-amd64
extern srand48(seed:i64) -> void abi sysv-amd64
extern drand48() -> f64 abi sysv-amd64
extern sqrt(value:f64) -> f64 abi sysv-amd64
extern sin(value:f64) -> f64 abi sysv-amd64
extern cos(value:f64) -> f64 abi sysv-amd64
extern acos(value:f64) -> f64 abi sysv-amd64
extern fabs(value:f64) -> f64 abi sysv-amd64
extern fflush(stream:u8*) -> i64 abi sysv-amd64
extern _exit(code:i64) -> void abi sysv-amd64

let Quantum = phrase { dictionary = true }

// Maksymalna liczba kubitów: 2^24 amplitud to 256 MB pamięci.
let Quantum:MAX_QUBITS = fn () -> i64 { return 24 }
let Quantum:PI = fn () -> f64 { return 3.14159265358979323846 }

record Quantum:State {
    n:i64
    size:i64
    re:f64*
    im:f64*
    names:u8**
    theta:f64*
    phi:f64*
    prepared:i64*
}

// -----------------------------------------------------------------------------
// Pomocnicze operacje na bitach. Język nie ma jeszcze operatorów bitowych,
// więc bit k liczby x to x / 2^k % 2.
// -----------------------------------------------------------------------------

let Quantum:pow2 = fn (k:i64) -> i64 {
    var result = 1
    var i = 0
    while i < k {
        result = result * 2
        i += 1
    }
    return result
}

let Quantum:check_qubit = fn (s:Quantum:State*, q:i64) -> i64 {
    if q < 0 || q >= s.n {
        printf("quantum: kubit %lld nie istnieje (rejestr ma %lld kubitów)\n", q, s.n)
        return 0
    }
    return 1
}

let Quantum:name = fn (handle:i64, t:i64) -> u8* {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    return s.names[t]
}

// -----------------------------------------------------------------------------
// Rejestr
// -----------------------------------------------------------------------------

let Quantum:new = fn () -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, malloc(64))
    s.n = 0
    s.size = 1
    s.re = cast(f64*, malloc(8))
    s.im = cast(f64*, malloc(8))
    s.re[0] = 1.0
    s.im[0] = 0.0
    var limit = Quantum:MAX_QUBITS()
    s.names = cast(u8**, malloc(cast(u64, limit * 8)))
    s.theta = cast(f64*, malloc(cast(u64, limit * 8)))
    s.phi = cast(f64*, malloc(cast(u64, limit * 8)))
    s.prepared = cast(i64*, malloc(cast(u64, limit * 8)))
    return cast(i64, s)
}

let Quantum:release = fn (handle:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    var i = 0
    while i < s.n {
        free(s.names[i])
        i += 1
    }
    free(cast(u8*, s.re))
    free(cast(u8*, s.im))
    free(cast(u8*, s.names))
    free(cast(u8*, s.theta))
    free(cast(u8*, s.phi))
    free(cast(u8*, s.prepared))
    free(cast(u8*, s))
    return 0
}

// Dokłada nowy kubit w stanie |0>. Zwraca jego indeks.
let Quantum:alloc = fn (handle:i64, name:u8*) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if s.n >= Quantum:MAX_QUBITS() {
        printf("quantum: przekroczono limit %lld kubitów\n", Quantum:MAX_QUBITS())
        return 0 - 1
    }
    var old_size = s.size
    var new_size = old_size * 2
    s.re = cast(f64*, realloc(cast(u8*, s.re), cast(u64, new_size * 8)))
    s.im = cast(f64*, realloc(cast(u8*, s.im), cast(u64, new_size * 8)))
    var i = old_size
    while i < new_size {
        s.re[i] = 0.0
        s.im[i] = 0.0
        i += 1
    }
    var index = s.n
    s.names[index] = strdup(name)
    s.theta[index] = 0.0
    s.phi[index] = 0.0
    s.prepared[index] = 0
    s.n = s.n + 1
    s.size = new_size
    return index
}

// -----------------------------------------------------------------------------
// Ogólna bramka jednokubitowa U = [[a, b], [c, d]] z maksymalnie dwoma
// kubitami kontrolnymi (wartość -1 oznacza brak kontroli).
// -----------------------------------------------------------------------------

let Quantum:apply = fn (handle:i64, c1:i64, c2:i64, t:i64,
                        ar:f64, ai:f64, br:f64, bi:f64,
                        cr:f64, ci:f64, dr:f64, di:f64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if Quantum:check_qubit(s, t) == 0 { return 0 }
    var mt = Quantum:pow2(t)
    var m1 = 0
    var m2 = 0
    if c1 >= 0 {
        if Quantum:check_qubit(s, c1) == 0 { return 0 }
        m1 = Quantum:pow2(c1)
    }
    if c2 >= 0 {
        if Quantum:check_qubit(s, c2) == 0 { return 0 }
        m2 = Quantum:pow2(c2)
    }
    var i = 0
    while i < s.size {
        var active = 1
        if i / mt % 2 == 1 { active = 0 }
        if m1 > 0 && i / m1 % 2 == 0 { active = 0 }
        if m2 > 0 && i / m2 % 2 == 0 { active = 0 }
        if active == 1 {
            var j = i + mt
            var xr = s.re[i]
            var xi = s.im[i]
            var yr = s.re[j]
            var yi = s.im[j]
            s.re[i] = ar * xr - ai * xi + br * yr - bi * yi
            s.im[i] = ar * xi + ai * xr + br * yi + bi * yr
            s.re[j] = cr * xr - ci * xi + dr * yr - di * yi
            s.im[j] = cr * xi + ci * xr + dr * yi + di * yr
        }
        i += 1
    }
    return 0
}

// -----------------------------------------------------------------------------
// Bramki
// -----------------------------------------------------------------------------

let Quantum:h = fn (handle:i64, t:i64) -> i64 {
    var k = 1.0 / sqrt(2.0)
    return Quantum:apply(handle, 0 - 1, 0 - 1, t, k, 0.0, k, 0.0, k, 0.0, 0.0 - k, 0.0)
}

let Quantum:x = fn (handle:i64, c1:i64, c2:i64, t:i64) -> i64 {
    return Quantum:apply(handle, c1, c2, t, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 0.0)
}

let Quantum:y = fn (handle:i64, c1:i64, t:i64) -> i64 {
    return Quantum:apply(handle, c1, 0 - 1, t, 0.0, 0.0, 0.0, 0.0 - 1.0, 0.0, 1.0, 0.0, 0.0)
}

let Quantum:z = fn (handle:i64, c1:i64, t:i64) -> i64 {
    return Quantum:apply(handle, c1, 0 - 1, t, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 - 1.0, 0.0)
}

// Bramka fazowa P(phi) = diag(1, e^(i*phi)). S = P(pi/2), T = P(pi/4).
let Quantum:phase = fn (handle:i64, c1:i64, t:i64, angle:f64) -> i64 {
    return Quantum:apply(handle, c1, 0 - 1, t, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, cos(angle), sin(angle))
}

let Quantum:rx = fn (handle:i64, t:i64, angle:f64) -> i64 {
    var c = cos(angle / 2.0)
    var s = sin(angle / 2.0)
    return Quantum:apply(handle, 0 - 1, 0 - 1, t, c, 0.0, 0.0, 0.0 - s, 0.0, 0.0 - s, c, 0.0)
}

let Quantum:ry = fn (handle:i64, t:i64, angle:f64) -> i64 {
    var c = cos(angle / 2.0)
    var s = sin(angle / 2.0)
    return Quantum:apply(handle, 0 - 1, 0 - 1, t, c, 0.0, 0.0 - s, 0.0, s, 0.0, c, 0.0)
}

let Quantum:rz = fn (handle:i64, t:i64, angle:f64) -> i64 {
    var c = cos(angle / 2.0)
    var s = sin(angle / 2.0)
    return Quantum:apply(handle, 0 - 1, 0 - 1, t, c, 0.0 - s, 0.0, 0.0, 0.0, 0.0, c, s)
}

let Quantum:swap = fn (handle:i64, a:i64, b:i64) -> i64 {
    Quantum:x(handle, a, 0 - 1, b)
    Quantum:x(handle, b, 0 - 1, a)
    Quantum:x(handle, a, 0 - 1, b)
    return 0
}

// Bariera nie zmienia stanu. Ma znaczenie tylko na sprzęcie, gdzie zabrania
// kompilatorowi upraszczać obwód ponad nią (zob. qasm.rl).
let Quantum:fence = fn (handle:i64, a:i64, b:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    Quantum:check_qubit(s, a)
    Quantum:check_qubit(s, b)
    return 0
}

// -----------------------------------------------------------------------------
// Pomiar i przygotowanie stanów
// -----------------------------------------------------------------------------

let Quantum:set_seed = fn (value:i64) -> i64 {
    srand48(value)
    return 0
}

let Quantum:clock_seed = fn () -> i64 {
    srand48(time(cast(u8*, 0)))
    return 0
}

// Prawdopodobieństwo, że kubit t da wynik 1.
let Quantum:prob_one = fn (handle:i64, t:i64) -> f64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    var m = Quantum:pow2(t)
    var p = 0.0
    var i = 0
    while i < s.size {
        if i / m % 2 == 1 {
            p = p + s.re[i] * s.re[i] + s.im[i] * s.im[i]
        }
        i += 1
    }
    return p
}

// Pomiar w bazie obliczeniowej: losuje wynik zgodnie z regułą Borna
// i redukuje stan do gałęzi zgodnej z wynikiem.
let Quantum:do_measure = fn (handle:i64, t:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if Quantum:check_qubit(s, t) == 0 { return 0 - 1 }
    var p1 = Quantum:prob_one(handle, t)
    var outcome = 0
    if drand48() < p1 { outcome = 1 }
    var p = p1
    if outcome == 0 { p = 1.0 - p1 }
    var norm = 1.0 / sqrt(p)
    var m = Quantum:pow2(t)
    var i = 0
    while i < s.size {
        if i / m % 2 == outcome {
            s.re[i] = s.re[i] * norm
            s.im[i] = s.im[i] * norm
        } else {
            s.re[i] = 0.0
            s.im[i] = 0.0
        }
        i += 1
    }
    return outcome
}

let Quantum:do_reset = fn (handle:i64, t:i64) -> i64 {
    if Quantum:do_measure(handle, t) == 1 {
        Quantum:x(handle, 0 - 1, 0 - 1, t)
    }
    return 0
}

// Przygotowuje kubit (w stanie |0>) w stanie
//   cos(theta/2)|0> + e^(i*phi) sin(theta/2)|1>
// i zapamiętuje kąty, żeby można było potem sprawdzić wierność stanu.
let Quantum:init_state = fn (handle:i64, t:i64, theta:f64, phi:f64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if Quantum:check_qubit(s, t) == 0 { return 0 }
    Quantum:ry(handle, t, theta)
    Quantum:phase(handle, 0 - 1, t, phi)
    s.theta[t] = theta
    s.phi[t] = phi
    s.prepared[t] = 1
    return 0
}

// Losowy stan z rozkładu jednostajnego na sferze Blocha.
let Quantum:init_random = fn (handle:i64, t:i64) -> i64 {
    var theta = acos(1.0 - 2.0 * drand48())
    var phi = 2.0 * Quantum:PI() * drand48()
    return Quantum:init_state(handle, t, theta, phi)
}

// Wierność kubitu t względem stanu, w jakim przygotowano kubit ref:
//   F = <psi| rho_t |psi>
// Liczona przez odwrócenie przygotowania na kubicie t i odczyt P(0).
// Stan rejestru jest potem przywracany.
let Quantum:get_fidelity = fn (handle:i64, t:i64, ref:i64) -> f64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if Quantum:check_qubit(s, t) == 0 { return 0.0 }
    if Quantum:check_qubit(s, ref) == 0 { return 0.0 }
    if s.prepared[ref] == 0 {
        printf("quantum: kubit %s nie był przygotowany przez prepare\n", s.names[ref])
        return 0.0
    }
    var theta = s.theta[ref]
    var phi = s.phi[ref]
    Quantum:phase(handle, 0 - 1, t, 0.0 - phi)
    Quantum:ry(handle, t, 0.0 - theta)
    var f = 1.0 - Quantum:prob_one(handle, t)
    Quantum:ry(handle, t, theta)
    Quantum:phase(handle, 0 - 1, t, phi)
    return f
}

// Zwraca 1, jeśli wierność różni się od 1 o mniej niż 1e-9.
let Quantum:same = fn (handle:i64, t:i64, ref:i64) -> i64 {
    var f = Quantum:get_fidelity(handle, t, ref)
    if fabs(1.0 - f) < 0.000000001 { return 1 }
    printf("quantum: wierność %s względem %s wynosi %.12f\n", Quantum:name(handle, t), Quantum:name(handle, ref), f)
    return 0
}

// -----------------------------------------------------------------------------
// Wyświetlanie
// -----------------------------------------------------------------------------

// Wypisuje niezerowe amplitudy. Kubity w kolejności deklaracji od lewej.
let Quantum:print_state = fn (handle:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    printf("  stan |")
    var k = 0
    while k < s.n {
        if k > 0 { printf(" ") }
        printf("%s", s.names[k])
        k += 1
    }
    printf(">\n")
    var i = 0
    while i < s.size {
        var p = s.re[i] * s.re[i] + s.im[i] * s.im[i]
        if p > 0.000000000001 {
            printf("    |")
            var q = 0
            while q < s.n {
                printf("%lld", i / Quantum:pow2(q) % 2)
                q += 1
            }
            printf(">  %+.4f %+.4fi   p = %.4f\n", s.re[i], s.im[i], p)
        }
        i += 1
    }
    return 0
}

// Wektor Blocha kubitu t z macierzy gęstości zredukowanej:
//   x = 2 Re(rho01), y = -2 Im(rho01), z = rho00 - rho11
let Quantum:print_bloch = fn (handle:i64, t:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if Quantum:check_qubit(s, t) == 0 { return 0 }
    var m = Quantum:pow2(t)
    var p0 = 0.0
    var p1 = 0.0
    var r01 = 0.0
    var i01 = 0.0
    var i = 0
    while i < s.size {
        if i / m % 2 == 0 {
            var j = i + m
            p0 = p0 + s.re[i] * s.re[i] + s.im[i] * s.im[i]
            p1 = p1 + s.re[j] * s.re[j] + s.im[j] * s.im[j]
            // rho01 += a_i * conj(a_j)
            r01 = r01 + s.re[i] * s.re[j] + s.im[i] * s.im[j]
            i01 = i01 + s.im[i] * s.re[j] - s.re[i] * s.im[j]
        }
        i += 1
    }
    var x = 2.0 * r01
    var y = 0.0 - 2.0 * i01
    var z = p0 - p1
    printf("  %-8s Bloch (x, y, z) = (%+.4f, %+.4f, %+.4f)\n", s.names[t], x, y, z)
    return 0
}

// -----------------------------------------------------------------------------
// Sprawdzenia w obwodach
// -----------------------------------------------------------------------------

let Quantum:fail = fn (circuit:u8*, text:u8*) -> i64 {
    printf("quantum: obwód %s: niespełnione sprawdzenie: %s\n", circuit, text)
    fflush(cast(u8*, 0))
    _exit(1)
    return 0
}

// Funkcje dostępne w treści obwodów.
fn pi() -> f64 {
    return 3.14159265358979323846
}

// Porównanie liczb rzeczywistych z tolerancją 1e-9.
fn approx(a:f64, b:f64) -> i64 {
    if fabs(a - b) < 0.000000001 { return 1 }
    return 0
}

let quantum_seed = <Quantum:set_seed>
let quantum_seed_from_clock = <Quantum:clock_seed>

// -----------------------------------------------------------------------------
// Składnia języka obwodów
//
// `circuit nazwa { ... }` definiuje funkcję natywną `nazwa() -> i64`.
// Każde wywołanie tworzy nowy rejestr `qs` i zwalnia go na końcu.
// Obwód może zwrócić wynik instrukcją `return`, domyślnie zwraca 0.
//
// Treść bloku jest wstawiana jako ciało `if 1 == 1 { ... }`, bo zagnieżdżony
// blok `{ ... }` w funkcji jest obecnie pomijany przez kompilator RecurLoop.
// -----------------------------------------------------------------------------

syntax circuit <name:id> <body:block> => fn ${name}() -> i64 {
    var qs = Quantum:new()
    var cname:u8* = "${name}"
    defer Quantum:release(qs)
    if 1 == 1 ${body}
    return 0
}

// Wariant z parametrami: `circuit nazwa(a:i64, kat:f64) { ... }`.
syntax extend circuit <name:id> "(" <params:raw> ")" <body:block> => fn ${name}(${params}) -> i64 {
    var qs = Quantum:new()
    var cname:u8* = "${name}"
    defer Quantum:release(qs)
    if 1 == 1 ${body}
    return 0
}

syntax say <text:string> => printf("%s\n", ${text})

// `experiment nazwa { ... }` definiuje funkcję natywną bez rejestru, na przykład
// do wielokrotnego uruchamiania obwodów i zbierania statystyk. Pętle warto
// pisać właśnie tutaj: pętla `while` na poziomie skryptu jest w RecurLoop
// wielokrotnie wolniejsza od natywnej.
syntax experiment <name:id> <body:block> => fn ${name}() -> i64 {
    var cname:u8* = "${name}"
    if 1 == 1 ${body}
    return 0
}

// Wariant z parametrami: `experiment nazwa(n:i64) { ... }`.
syntax extend experiment <name:id> "(" <params:raw> ")" <body:block> => fn ${name}(${params}) -> i64 {
    var cname:u8* = "${name}"
    if 1 == 1 ${body}
    return 0
}

syntax qubit <name:id> => var ${name} = Quantum:alloc(qs, "${name}")

syntax seed <value:expr> => quantum_seed(${value})

syntax H <t:expr> => Quantum:h(qs, ${t})
syntax X <t:expr> => Quantum:x(qs, 0 - 1, 0 - 1, ${t})
syntax Y <t:expr> => Quantum:y(qs, 0 - 1, ${t})
syntax Z <t:expr> => Quantum:z(qs, 0 - 1, ${t})
syntax S <t:expr> => Quantum:phase(qs, 0 - 1, ${t}, pi() / 2.0)
syntax T <t:expr> => Quantum:phase(qs, 0 - 1, ${t}, pi() / 4.0)
syntax RX "(" <angle:expr> ")" <t:expr> => Quantum:rx(qs, ${t}, ${angle})
syntax RY "(" <angle:expr> ")" <t:expr> => Quantum:ry(qs, ${t}, ${angle})
syntax RZ "(" <angle:expr> ")" <t:expr> => Quantum:rz(qs, ${t}, ${angle})
syntax P "(" <angle:expr> ")" <t:expr> => Quantum:phase(qs, 0 - 1, ${t}, ${angle})

syntax CNOT <c:expr> "," <t:expr> => Quantum:x(qs, ${c}, 0 - 1, ${t})
syntax CZ <c:expr> "," <t:expr> => Quantum:z(qs, ${c}, ${t})
syntax SWAP <a:expr> "," <b:expr> => Quantum:swap(qs, ${a}, ${b})
syntax TOFFOLI <c1:expr> "," <c2:expr> "," <t:expr> => Quantum:x(qs, ${c1}, ${c2}, ${t})
syntax barrier <a:expr> "," <b:expr> => Quantum:fence(qs, ${a}, ${b})

syntax measure <t:id> "->" <name:id> => var ${name} = Quantum:do_measure(qs, ${t})
syntax probability <t:id> "->" <name:id> => var ${name} = Quantum:prob_one(qs, ${t})
syntax fidelity <t:id> "," <ref:id> "->" <name:id> => var ${name} = Quantum:get_fidelity(qs, ${t}, ${ref})
syntax reset <t:expr> => Quantum:do_reset(qs, ${t})

syntax prepare <t:expr> random => Quantum:init_random(qs, ${t})
syntax extend prepare <t:expr> "(" <theta:expr> "," <phi:expr> ")" => Quantum:init_state(qs, ${t}, ${theta}, ${phi})

syntax show "state" => Quantum:print_state(qs)
syntax extend show bloch <t:expr> => Quantum:print_bloch(qs, ${t})

// Warunek zależny od wyniku pomiaru. W symulatorze działa jak `if`, a w qasm.rl
// staje się warunkiem wykonywanym na komputerze kwantowym w trakcie obwodu.
syntax when <bit:id> <body:block> => if ${bit} == 1 ${body}

syntax check <cond:expr> => if !(${cond}) { Quantum:fail(cname, "${cond}") }
syntax expect <t:expr> "==" <ref:expr> => if Quantum:same(qs, ${t}, ${ref}) == 0 { Quantum:fail(cname, "expect ${t} == ${ref}") }

quantum_seed_from_clock()
