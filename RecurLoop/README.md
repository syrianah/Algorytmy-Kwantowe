# Quantum: quantum circuits in RecurLoop

[RecurLoop](https://github.com/RecurLoop/RecurLoop) libraries that add
quantum circuit syntax to the language. Gates, measurements and `circuit`
blocks are new language phrases defined in the libraries themselves, with no
changes to the compiler.

The same circuit has two backends, chosen by the included library:

- **`quantum.rl`** simulates the circuit. Every circuit compiles to a native
  function that computes the state vector.
- **`qasm.rl`** compiles the circuit to OpenQASM 3, which can run on an IBM
  quantum computer. The guide is in [`ibm/README.md`](ibm/README.md).

Teleportation, superdense coding, the CHSH game and the QFT written in this
language have run on real IBM processors. The results are in
[`ibm/README.md`](ibm/README.md#results-on-real-hardware).

```rl
include "quantum.rl"

circuit bell(verbose:i64) {
    qubit a
    qubit b
    H a
    CNOT a, b
    measure a -> ma
    measure b -> mb
    check ma == mb
    return ma
}

bell(0)
```

## Running

You need RecurLoop built for Linux x86-64:

```bash
git clone https://github.com/RecurLoop/RecurLoop.git
cd RecurLoop && make
```

Tests and all examples:

```bash
./run.sh /path/to/RecurLoop/build/Release/bin/recurloop
```

A single example:

```bash
recurloop --file examples/teleportation.rl
```

## Files

| File | Contents |
|---|---|
| `quantum.rl` | The simulator engine and the circuit language syntax |
| `qasm.rl` | A compiler of the same circuits to OpenQASM 3 |
| `qft.rl` | The quantum Fourier transform and its inverse, for both backends |
| `grover.rl` | Grover's search on 2 or 3 qubits: oracle, diffusion and the whole search, for both backends |
| `ibm/` | All protocols on a real IBM quantum computer |
| `tests.rl` | Tests of every gate, measurement and fidelity |
| `examples/bell.rl` | Bell state and measurement statistics |
| `examples/chsh.rl` | The CHSH game with and without entanglement, the S value and the classical bound |
| `examples/grover.rl` | Grover's search step by step and the success probability after 0 to 5 iterations |
| `examples/qft.rl` | QFT of a number, period finding and reading a number stored in phases |
| `examples/superdense.rl` | Superdense coding: four messages step by step and 10,000 runs |
| `examples/teleportation.rl` | The full teleportation protocol step by step and 10,000 random runs |
| `run.sh` | Runs the tests and examples |
| `benchmark/` | The same simulator in Python, NumPy and Rust plus a performance comparison, results in `benchmark/README.md` |

## The circuit language

### Definitions

| Syntax | Meaning |
|---|---|
| `circuit name { ... }` | A circuit as a native function `name() -> i64` with its own register |
| `circuit name(a:i64, angle:f64) { ... }` | A circuit with parameters |
| `experiment name { ... }` | A native function without a register, for example for statistics |
| `experiment name(n:i64) { ... }` | The same with parameters |
| `qubit name` | A new qubit in state \|0> |
| `qubits r[n]` | A register of n qubits, `r[0]`, `r[1]`, ... In QASM `qubit[n] r;` |
| `seed 42` | A fixed random seed; by default the seed comes from the clock |

### Gates

| Syntax | Gate |
|---|---|
| `H q`, `X q`, `Y q`, `Z q` | Hadamard and Pauli gates |
| `S q`, `T q` | Phases pi/2 and pi/4 |
| `P(angle) q` | Phase diag(1, e^(i angle)) |
| `RX(angle) q`, `RY(angle) q`, `RZ(angle) q` | Rotations about the Bloch sphere axes |
| `CNOT c, t`, `CZ c, t` | Controlled gates |
| `CP(angle) c, t` | Controlled phase: e^(i angle) when both qubits are 1 |
| `SWAP a, b` | Qubit swap |
| `TOFFOLI c1, c2, t` | Doubly controlled NOT |
| `CCZ a, b, c` | Doubly controlled Z: flips the sign when all three qubits are 1 |
| `barrier a, b` | No effect in simulation. On hardware it stops the compiler from simplifying the circuit across this point |

### Measurement and preparation

| Syntax | Meaning |
|---|---|
| `measure q -> m` | Measurement with a Born-rule draw and state collapse |
| `measure all r -> x` | Measures a whole register as a number, `r[0]` is the lowest bit |
| `probability q -> p` | Probability of outcome 1 without measuring |
| `reset q` | Brings a qubit back to \|0> |
| `prepare q random` | A random state, uniform on the Bloch sphere |
| `prepare q (theta, phi)` | The state cos(theta/2)\|0> + e^(i phi) sin(theta/2)\|1> |
| `fidelity q, ref -> f` | Fidelity of q with respect to the state ref was prepared in |

### Display and checks

| Syntax | Meaning |
|---|---|
| `show state` | Nonzero amplitudes, qubits in declaration order from the left |
| `show bloch q` | Bloch vector of a qubit from the reduced density matrix |
| `say "text"` | Prints text |
| `when bit { ... }` | A block run when the measured bit is 1. In QASM it runs on the hardware |
| `check condition` | Exits the program with code 1 if the condition is false |
| `expect q == ref` | Checks that the fidelity of q with respect to ref is 1 |

Ordinary RecurLoop code works inside a circuit: `if`, `while`, `var`,
`return`, `printf`, and the functions `pi()` and `approx(a, b)`.

## How the simulator works

A register of n qubits is a vector of 2^n complex amplitudes. Qubit k
corresponds to bit k of the amplitude index. A single-qubit gate changes only
the amplitude pairs that differ in bit k, so there is no need to build a
2^n by 2^n matrix with Kronecker products. Control qubits restrict the change
to the pairs whose control bits are 1.

A measurement computes the outcome probability, draws the outcome, zeroes the
other branch and renormalizes the rest. Fidelity with respect to a prepared
state is computed by undoing the preparation on the qubit under test and
reading the probability of outcome 0, after which the state is restored.

## What it fixes compared with the old simulators

| Problem in the archived simulators | Here |
|---|---|
| Gates as full Kronecker-product matrices | Only amplitude pairs change, memory 2^n instead of 4^n |
| Teleportation always assumes measurement result 01 and an X correction | Random measurement with X and Z corrections depending on the result |
| No check that Bob received the right state | `expect bob == psi` after every teleportation |
| The `\|\|` condition in `Qubit::new` is always true | States arise only from unitary gates |
| CHSH always measures 01 and rotates qubits by half the needed angle | A real measurement and angles giving 85.4% wins, S = 2.83 |
| Superdense coding picks the measurement projector from the known message | Bob measures both qubits normally and only then learns the message |

## RecurLoop limitations found while writing the library

RecurLoop is a research project. These all have workarounds in the library,
but are worth reporting to the language's author:

1. **No bitwise operators.** `&`, `|`, `^`, `<<`, `>>` do not work in
   functions. Bit k of x is computed as `x / 2^k % 2`.
2. **A nested block in a function is skipped.** Statements in `{ ... }`
   inside an `fn` do not run and no error is reported. That is why the
   circuit body is inserted as the body of `if 1 == 1 { ... }`.
   ```rl
   fn f() -> i64 {
       var m = 1
       {
           m = 2
       }
       return m
   }
   print f()   // prints 1
   ```
3. **A script-level `while` loop has quadratic cost.** An empty loop of 1000
   iterations takes about 3 s, of 4000 iterations about 24 s. The same loop
   in an `fn` is instant, hence `experiment`.
4. **Native calls from a script support only integers.** An `f64` can be
   neither passed nor returned, so angles are given inside circuits.
5. **A `syntax` keyword matches inside qualified names.** In a function
   `Quantum:measure(...)` is recognized as the `measure` statement. Library
   functions therefore have names that do not start with keywords.
6. **A call `Ns:f(...)` does not work as a standalone script-level
   statement**, although it works in an expression. The workaround is an
   alias `let f = <Ns:f>`.
7. **A `<t:expr>` capture swallows `}` on the same line.** Writing
   `if m == 1 { X bob }` is an error; the gate has to go on its own line.
8. **`assert` does not work in functions**, hence the custom `check`.
9. **A `syntax` pattern cannot be empty**, so it is `show state` rather than
   a bare `show`. This is a deliberate decision in the RecurLoop code.

## Plans

1. The Deutsch-Jozsa algorithm, and Grover's search on more qubits.
2. Phase estimation and Shor's algorithm for small numbers, built on `qft.rl`.
3. Gates on whole registers, for example `H all r`.
4. Exporting the libraries to `quantum.rli` and `qasm.rli` images loaded with
   `--library`.
