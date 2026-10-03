// =============================================================================
// Quantum: a quantum circuit simulator library for RecurLoop
//
// The engine stores the state vector (2^n complex amplitudes) and applies
// gates in place, touching only the amplitude pairs a gate acts on. It never
// builds full 2^n x 2^n matrices with Kronecker products.
//
// Qubit k corresponds to bit k of the amplitude index. New qubits are added
// in state |0> as the next, higher bits.
//
// Usage:
//   include "quantum.rl"
//
//   circuit bell {
//       qubit a
//       qubit b
//       H a
//       CNOT a, b
//       measure a -> result
//       show state
//       return result
//   }
//
//   bell()
//
// The full syntax reference is in README.md.
// =============================================================================

link shared "c"
link shared "m"

extern malloc(size:u64) -> u8* abi sysv-amd64
extern realloc(pointer:u8*, size:u64) -> u8* abi sysv-amd64
extern free(pointer:u8*) -> void abi sysv-amd64
extern strdup(text:u8*) -> u8* abi sysv-amd64
extern printf(format:u8*, ...) -> i64 abi sysv-amd64
extern snprintf(out:u8*, size:u64, format:u8*, ...) -> i64 abi sysv-amd64
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

// Maximum number of qubits: 2^24 amplitudes take 256 MB of memory.
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
    indices:i64*
    sizes:i64*
}

// -----------------------------------------------------------------------------
// Bit helpers. The language has no bitwise operators yet, so bit k of x is
// x / 2^k % 2.
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
        printf("quantum: qubit %lld does not exist (the register has %lld qubits)\n", q, s.n)
        return 0
    }
    return 1
}

let Quantum:name = fn (handle:i64, t:i64) -> u8* {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    return s.names[t]
}

// -----------------------------------------------------------------------------
// Register
// -----------------------------------------------------------------------------

let Quantum:new = fn () -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, malloc(80))
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
    // indices[k] = k. A qubit register is a pointer into this array.
    s.indices = cast(i64*, malloc(cast(u64, limit * 8)))
    s.sizes = cast(i64*, malloc(cast(u64, limit * 8)))
    var k = 0
    while k < limit {
        s.indices[k] = k
        s.sizes[k] = 1
        k += 1
    }
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
    free(cast(u8*, s.indices))
    free(cast(u8*, s.sizes))
    free(cast(u8*, s))
    return 0
}

// Adds a new qubit in state |0>. Returns its index.
let Quantum:alloc = fn (handle:i64, name:u8*) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if s.n >= Quantum:MAX_QUBITS() {
        printf("quantum: limit of %lld qubits exceeded\n", Quantum:MAX_QUBITS())
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

// A register of count qubits named name[0], name[1], ... Returns a pointer to
// their indices, so in a circuit r[k] is the index of the register's k-th qubit.
let Quantum:alloc_reg = fn (handle:i64, name:u8*, count:i64) -> i64* {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    var first = s.n
    var label:u8* = malloc(64)
    var k = 0
    while k < count {
        snprintf(label, 64, "%s[%lld]", name, k)
        Quantum:alloc(handle, label)
        k += 1
    }
    free(label)
    s.sizes[first] = count
    return cast(i64*, cast(i64, s.indices) + 8 * first)
}

// -----------------------------------------------------------------------------
// General single-qubit gate U = [[a, b], [c, d]] with up to two control
// qubits (-1 means no control).
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
// Gates
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

// Phase gate P(phi) = diag(1, e^(i*phi)). S = P(pi/2), T = P(pi/4).
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

// A barrier does not change the state. It only matters on hardware, where it
// stops the compiler from simplifying the circuit across it (see qasm.rl).
let Quantum:fence = fn (handle:i64, a:i64, b:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    Quantum:check_qubit(s, a)
    Quantum:check_qubit(s, b)
    return 0
}

// -----------------------------------------------------------------------------
// Measurement and state preparation
// -----------------------------------------------------------------------------

let Quantum:set_seed = fn (value:i64) -> i64 {
    srand48(value)
    return 0
}

let Quantum:clock_seed = fn () -> i64 {
    srand48(time(cast(u8*, 0)))
    return 0
}

// Probability that qubit t measures 1.
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

// Measurement in the computational basis: draws the outcome by the Born rule
// and collapses the state to the matching branch.
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

// Measures a whole register. Qubit r[k] gives bit k of the result, so the
// result is the number held in the register, with r[0] as the least
// significant bit.
let Quantum:read_reg = fn (handle:i64, r:i64*) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    var count = s.sizes[r[0]]
    var value = 0
    var k = 0
    while k < count {
        value += Quantum:do_measure(handle, r[k]) * Quantum:pow2(k)
        k += 1
    }
    return value
}

let Quantum:do_reset = fn (handle:i64, t:i64) -> i64 {
    if Quantum:do_measure(handle, t) == 1 {
        Quantum:x(handle, 0 - 1, 0 - 1, t)
    }
    return 0
}

// Prepares a qubit (in state |0>) in the state
//   cos(theta/2)|0> + e^(i*phi) sin(theta/2)|1>
// and remembers the angles so the state's fidelity can be checked later.
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

// Random state, uniformly distributed on the Bloch sphere.
let Quantum:init_random = fn (handle:i64, t:i64) -> i64 {
    var theta = acos(1.0 - 2.0 * drand48())
    var phi = 2.0 * Quantum:PI() * drand48()
    return Quantum:init_state(handle, t, theta, phi)
}

// Fidelity of qubit t with respect to the state qubit ref was prepared in:
//   F = <psi| rho_t |psi>
// Computed by undoing the preparation on qubit t and reading P(0).
// The register state is restored afterwards.
let Quantum:get_fidelity = fn (handle:i64, t:i64, ref:i64) -> f64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    if Quantum:check_qubit(s, t) == 0 { return 0.0 }
    if Quantum:check_qubit(s, ref) == 0 { return 0.0 }
    if s.prepared[ref] == 0 {
        printf("quantum: qubit %s was not set up with prepare\n", s.names[ref])
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

// Returns 1 if the fidelity differs from 1 by less than 1e-9.
let Quantum:same = fn (handle:i64, t:i64, ref:i64) -> i64 {
    var f = Quantum:get_fidelity(handle, t, ref)
    if fabs(1.0 - f) < 0.000000001 { return 1 }
    printf("quantum: fidelity of %s with respect to %s is %.12f\n", Quantum:name(handle, t), Quantum:name(handle, ref), f)
    return 0
}

// -----------------------------------------------------------------------------
// Display
// -----------------------------------------------------------------------------

// Prints the nonzero amplitudes. Qubits appear in declaration order from the left.
let Quantum:print_state = fn (handle:i64) -> i64 {
    var s:Quantum:State* = cast(Quantum:State*, handle)
    printf("  state |")
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

// Bloch vector of qubit t from the reduced density matrix:
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
// Checks inside circuits
// -----------------------------------------------------------------------------

let Quantum:fail = fn (circuit:u8*, text:u8*) -> i64 {
    printf("quantum: circuit %s: check failed: %s\n", circuit, text)
    fflush(cast(u8*, 0))
    _exit(1)
    return 0
}

// Functions available inside circuits.
fn pi() -> f64 {
    return 3.14159265358979323846
}

// Compares real numbers with a tolerance of 1e-9.
fn approx(a:f64, b:f64) -> i64 {
    if fabs(a - b) < 0.000000001 { return 1 }
    return 0
}

let quantum_seed = <Quantum:set_seed>
let quantum_seed_from_clock = <Quantum:clock_seed>

// -----------------------------------------------------------------------------
// Circuit language syntax
//
// `circuit name { ... }` defines a native function `name() -> i64`.
// Every call creates a new register `qs` and frees it at the end.
// A circuit can return a result with `return`; by default it returns 0.
//
// The block body is inserted as the body of `if 1 == 1 { ... }`, because the
// RecurLoop compiler currently skips a nested `{ ... }` block inside a function.
// -----------------------------------------------------------------------------

syntax circuit <name:id> <body:block> => fn ${name}() -> i64 {
    var qs = Quantum:new()
    var cname:u8* = "${name}"
    defer Quantum:release(qs)
    if 1 == 1 ${body}
    return 0
}

// Variant with parameters: `circuit name(a:i64, angle:f64) { ... }`.
syntax extend circuit <name:id> "(" <params:raw> ")" <body:block> => fn ${name}(${params}) -> i64 {
    var qs = Quantum:new()
    var cname:u8* = "${name}"
    defer Quantum:release(qs)
    if 1 == 1 ${body}
    return 0
}

syntax say <text:string> => printf("%s\n", ${text})

// `experiment name { ... }` defines a native function without a register, for
// example to run circuits many times and collect statistics. Loops belong
// here: a script-level `while` loop in RecurLoop is many times slower than a
// native one.
syntax experiment <name:id> <body:block> => fn ${name}() -> i64 {
    var cname:u8* = "${name}"
    if 1 == 1 ${body}
    return 0
}

// Variant with parameters: `experiment name(n:i64) { ... }`.
syntax extend experiment <name:id> "(" <params:raw> ")" <body:block> => fn ${name}(${params}) -> i64 {
    var cname:u8* = "${name}"
    if 1 == 1 ${body}
    return 0
}

syntax qubit <name:id> => var ${name} = Quantum:alloc(qs, "${name}")
syntax qubits <name:id> "[" <count:expr> "]" => var ${name}:i64* = Quantum:alloc_reg(qs, "${name}", ${count})

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
syntax CP "(" <angle:expr> ")" <c:expr> "," <t:expr> => Quantum:phase(qs, ${c}, ${t}, ${angle})
syntax SWAP <a:expr> "," <b:expr> => Quantum:swap(qs, ${a}, ${b})
syntax TOFFOLI <c1:expr> "," <c2:expr> "," <t:expr> => Quantum:x(qs, ${c1}, ${c2}, ${t})
syntax barrier <a:expr> "," <b:expr> => Quantum:fence(qs, ${a}, ${b})

syntax measure <t:id> "->" <name:id> => var ${name} = Quantum:do_measure(qs, ${t})
syntax extend measure all <r:id> "->" <name:id> => var ${name} = Quantum:read_reg(qs, ${r})
syntax probability <t:id> "->" <name:id> => var ${name} = Quantum:prob_one(qs, ${t})
syntax fidelity <t:id> "," <ref:id> "->" <name:id> => var ${name} = Quantum:get_fidelity(qs, ${t}, ${ref})
syntax reset <t:expr> => Quantum:do_reset(qs, ${t})

syntax prepare <t:expr> random => Quantum:init_random(qs, ${t})
syntax extend prepare <t:expr> "(" <theta:expr> "," <phi:expr> ")" => Quantum:init_state(qs, ${t}, ${theta}, ${phi})

syntax show "state" => Quantum:print_state(qs)
syntax extend show bloch <t:expr> => Quantum:print_bloch(qs, ${t})

// A condition on a measurement result. In the simulator it acts like `if`; in
// qasm.rl it becomes a condition evaluated on the quantum computer mid-circuit.
syntax when <bit:id> <body:block> => if ${bit} == 1 ${body}

syntax check <cond:expr> => if !(${cond}) { Quantum:fail(cname, "${cond}") }
syntax expect <t:expr> "==" <ref:expr> => if Quantum:same(qs, ${t}, ${ref}) == 0 { Quantum:fail(cname, "expect ${t} == ${ref}") }

quantum_seed_from_clock()
