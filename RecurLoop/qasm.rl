// =============================================================================
// Qasm: kompilator obwodów do OpenQASM 3
//
// Te same słowa co quantum.rl, ale zamiast symulować, każdy obwód zapisuje
// program OpenQASM 3 do pliku `nazwa.qasm` w bieżącym katalogu. Taki plik
// można uruchomić na komputerze kwantowym IBM przez Qiskit.
//
// Wybór backendu to wybór biblioteki:
//   include "quantum.rl"   obwód się symuluje
//   include "qasm.rl"      obwód kompiluje się do OpenQASM 3
//
// Różnice względem symulatora:
// - `prepare q random` losuje kąty w czasie kompilacji i wpisuje je do pliku.
// - `expect q == ref` odwraca przygotowanie ref na q i mierzy q do bitu
//   expect_q. Na idealnym sprzęcie ten bit zawsze wynosi 0.
// - `barrier a, b` zabrania kompilatorowi Qiskit upraszczać obwód ponad
//   tym miejscem. Bez niej obwód o z góry znanym wyniku, jak kodowanie
//   supergęste, zostałby zredukowany do samych bramek X i pomiarów.
// - `when bit { ... }` staje się warunkiem `if` wykonywanym na komputerze
//   kwantowym w trakcie obwodu.
// - `probability`, `fidelity` i `check` nie istnieją, bo stanu kwantowego
//   nie da się odczytać na sprzęcie. `show` i `say` dają komentarze.
// =============================================================================

link shared "c"
link shared "m"
extern malloc(size:u64) -> u8* abi sysv-amd64
extern free(pointer:u8*) -> void abi sysv-amd64
extern strdup(text:u8*) -> u8* abi sysv-amd64
extern printf(format:u8*, ...) -> i64 abi sysv-amd64
extern fprintf(stream:u8*, format:u8*, ...) -> i64 abi sysv-amd64
extern fopen(path:u8*, mode:u8*) -> u8* abi sysv-amd64
extern fclose(stream:u8*) -> i64 abi sysv-amd64
extern snprintf(out:u8*, size:u64, format:u8*, ...) -> i64 abi sysv-amd64
extern time(out:u8*) -> i64 abi sysv-amd64
extern srand48(seed:i64) -> void abi sysv-amd64
extern drand48() -> f64 abi sysv-amd64
extern acos(value:f64) -> f64 abi sysv-amd64

let Qasm = phrase { dictionary = true }

record Qasm:Reg {
    n:i64
    names:u8**
    theta:f64*
    phi:f64*
    indent:i64
    out:u8*
}

let Qasm:new = fn (name:u8*) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, malloc(48))
    r.n = 0
    r.names = cast(u8**, malloc(8 * 64))
    r.theta = cast(f64*, malloc(8 * 64))
    r.phi = cast(f64*, malloc(8 * 64))
    r.indent = 0
    var path:u8* = malloc(512)
    snprintf(path, 512, "%s.qasm", name)
    r.out = fopen(path, "w")
    if !r.out {
        printf("qasm: nie można otworzyć pliku %s\n", path)
        free(path)
        return 0
    }
    printf("qasm: zapisuję %s\n", path)
    free(path)
    fprintf(r.out, "// Obwód %s wygenerowany przez RecurLoop z biblioteki qasm.rl\nOPENQASM 3.0;\ninclude \"stdgates.inc\";\n\n", name)
    return cast(i64, r)
}

let Qasm:release = fn (h:i64) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    var i = 0
    while i < r.n {
        free(r.names[i])
        i += 1
    }
    fclose(r.out)
    free(cast(u8*, r.names))
    free(cast(u8*, r.theta))
    free(cast(u8*, r.phi))
    free(cast(u8*, r))
    return 0
}

let Qasm:out = fn (h:i64) -> u8* {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    return r.out
}

let Qasm:pad = fn (h:i64) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    var i = 0
    while i < r.indent {
        fprintf(Qasm:out(h), "    ")
        i += 1
    }
    return 0
}

let Qasm:alloc = fn (h:i64, name:u8*) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    r.names[r.n] = strdup(name)
    fprintf(Qasm:out(h), "qubit %s;\n", name)
    r.n = r.n + 1
    return r.n - 1
}

let Qasm:nm = fn (h:i64, q:i64) -> u8* {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    return r.names[q]
}

let Qasm:g1 = fn (h:i64, gate:u8*, t:i64) -> i64 {
    Qasm:pad(h)
    fprintf(Qasm:out(h), "%s %s;\n", gate, Qasm:nm(h, t))
    return 0
}

let Qasm:g1a = fn (h:i64, gate:u8*, angle:f64, t:i64) -> i64 {
    Qasm:pad(h)
    fprintf(Qasm:out(h), "%s(%.17g) %s;\n", gate, angle, Qasm:nm(h, t))
    return 0
}

let Qasm:g2 = fn (h:i64, gate:u8*, a:i64, b:i64) -> i64 {
    Qasm:pad(h)
    fprintf(Qasm:out(h), "%s %s, %s;\n", gate, Qasm:nm(h, a), Qasm:nm(h, b))
    return 0
}

let Qasm:g3 = fn (h:i64, gate:u8*, a:i64, b:i64, c:i64) -> i64 {
    Qasm:pad(h)
    fprintf(Qasm:out(h), "%s %s, %s, %s;\n", gate, Qasm:nm(h, a), Qasm:nm(h, b), Qasm:nm(h, c))
    return 0
}

let Qasm:do_measure = fn (h:i64, t:i64, bit:u8*) -> i64 {
    Qasm:pad(h)
    fprintf(Qasm:out(h), "bit[1] %s;\n", bit)
    Qasm:pad(h)
    fprintf(Qasm:out(h), "%s[0] = measure %s;\n", bit, Qasm:nm(h, t))
    return 0
}

// Kąty losowane w czasie kompilacji: program QASM dostaje konkretny stan.
let Qasm:init_state = fn (h:i64, t:i64, theta:f64, phi:f64) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    r.theta[t] = theta
    r.phi[t] = phi
    Qasm:g1a(h, "ry", theta, t)
    Qasm:g1a(h, "p", phi, t)
    return 0
}

let Qasm:init_random = fn (h:i64, t:i64) -> i64 {
    var theta = acos(1.0 - 2.0 * drand48())
    var phi = 2.0 * 3.14159265358979323846 * drand48()
    return Qasm:init_state(h, t, theta, phi)
}

// expect t == ref na sprzęcie: odwrócenie przygotowania i pomiar.
// Jeśli t ma stan ref, wynik pomiaru to zawsze 0.
let Qasm:verify = fn (h:i64, t:i64, ref:i64) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    Qasm:pad(h)
    fprintf(Qasm:out(h), "// expect %s == %s: po odwróceniu przygotowania pomiar musi dać 0\n", Qasm:nm(h, t), Qasm:nm(h, ref))
    Qasm:g1a(h, "p", 0.0 - r.phi[ref], t)
    Qasm:g1a(h, "ry", 0.0 - r.theta[ref], t)
    Qasm:pad(h)
    fprintf(Qasm:out(h), "bit[1] expect_%s;\n", Qasm:nm(h, t))
    Qasm:pad(h)
    fprintf(Qasm:out(h), "expect_%s[0] = measure %s;\n", Qasm:nm(h, t), Qasm:nm(h, t))
    return 0
}

let Qasm:open_if = fn (h:i64, bit:u8*) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    Qasm:pad(h)
    fprintf(Qasm:out(h), "if (%s[0]) {\n", bit)
    r.indent = r.indent + 1
    return 0
}

let Qasm:close = fn (h:i64) -> i64 {
    var r:Qasm:Reg* = cast(Qasm:Reg*, h)
    r.indent = r.indent - 1
    Qasm:pad(h)
    fprintf(Qasm:out(h), "}\n")
    return 0
}

let Qasm:comment = fn (h:i64, text:u8*) -> i64 {
    Qasm:pad(h)
    fprintf(Qasm:out(h), "// %s\n", text)
    return 0
}

fn pi() -> f64 {
    return 3.14159265358979323846
}

let qasm_seed = fn (v:i64) -> i64 {
    srand48(v)
    return 0
}

syntax circuit <name:id> <body:block> => fn ${name}() -> i64 {
    var qs = Qasm:new("${name}")
    defer Qasm:release(qs)
    if 1 == 1 ${body}
    return 0
}

syntax extend circuit <name:id> "(" <params:raw> ")" <body:block> => fn ${name}(${params}) -> i64 {
    var qs = Qasm:new("${name}")
    defer Qasm:release(qs)
    if 1 == 1 ${body}
    return 0
}

syntax qubit <name:id> => var ${name} = Qasm:alloc(qs, "${name}")
syntax seed <value:expr> => qasm_seed(${value})

syntax H <t:expr> => Qasm:g1(qs, "h", ${t})
syntax X <t:expr> => Qasm:g1(qs, "x", ${t})
syntax Y <t:expr> => Qasm:g1(qs, "y", ${t})
syntax Z <t:expr> => Qasm:g1(qs, "z", ${t})
syntax S <t:expr> => Qasm:g1(qs, "s", ${t})
syntax T <t:expr> => Qasm:g1(qs, "t", ${t})
syntax RX "(" <angle:expr> ")" <t:expr> => Qasm:g1a(qs, "rx", ${angle}, ${t})
syntax RY "(" <angle:expr> ")" <t:expr> => Qasm:g1a(qs, "ry", ${angle}, ${t})
syntax RZ "(" <angle:expr> ")" <t:expr> => Qasm:g1a(qs, "rz", ${angle}, ${t})
syntax P "(" <angle:expr> ")" <t:expr> => Qasm:g1a(qs, "p", ${angle}, ${t})
syntax CNOT <c:expr> "," <t:expr> => Qasm:g2(qs, "cx", ${c}, ${t})
syntax CZ <c:expr> "," <t:expr> => Qasm:g2(qs, "cz", ${c}, ${t})
syntax SWAP <a:expr> "," <b:expr> => Qasm:g2(qs, "swap", ${a}, ${b})
syntax TOFFOLI <c1:expr> "," <c2:expr> "," <t:expr> => Qasm:g3(qs, "ccx", ${c1}, ${c2}, ${t})
syntax barrier <a:expr> "," <b:expr> => Qasm:g2(qs, "barrier", ${a}, ${b})

syntax measure <t:id> "->" <name:id> => var ${name} = Qasm:do_measure(qs, ${t}, "${name}")
syntax reset <t:expr> => Qasm:g1(qs, "reset", ${t})
syntax prepare <t:expr> random => Qasm:init_random(qs, ${t})
syntax extend prepare <t:expr> "(" <theta:expr> "," <phi:expr> ")" => Qasm:init_state(qs, ${t}, ${theta}, ${phi})

// Warunek zależny od wyniku pomiaru, wykonywany na komputerze kwantowym.
syntax when <bit:id> <body:block> => if 1 == 1 {
    Qasm:open_if(qs, "${bit}")
    if 1 == 1 ${body}
    Qasm:close(qs)
}

syntax show "state" => Qasm:comment(qs, "show state")
syntax extend show bloch <t:expr> => Qasm:comment(qs, "show bloch")
syntax say <text:string> => Qasm:comment(qs, ${text})
syntax expect <t:expr> "==" <ref:expr> => Qasm:verify(qs, ${t}, ${ref})

let qasm_clock_seed = fn () -> i64 {
    srand48(time(cast(u8*, 0)))
    return 0
}
qasm_clock_seed()
