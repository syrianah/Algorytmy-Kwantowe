# Quantum algorithms

Simulations of quantum algorithms and protocols. The main part of the repo is
a quantum circuit language built in
[RecurLoop](https://github.com/RecurLoop/RecurLoop), where gates,
measurements and `circuit` blocks are new language constructs. Circuits can
be simulated, or compiled to OpenQASM 3 and run on an IBM quantum computer.

Results on real IBM processors, 3 October 2026, 4000 runs of every circuit.
The last column is the random result or the best one possible without
entanglement. Details are in
[`RecurLoop/ibm/README.md`](RecurLoop/ibm/README.md#results-on-real-hardware).

| Algorithm | Processor | Result | Without quantum advantage |
|---|---|---:|---:|
| Teleportation | `ibm_kingston` | 94.5% | 50% |
| Superdense coding | `ibm_fez` | 96.8% | 25% |
| CHSH game | `ibm_fez` | S = 2.70 | S ≤ 2 |
| QFT, reading a number from phases | `ibm_fez` | 90.5% | 12.5% |

This is teleportation in the language:

```rl
circuit teleportation {
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
}
```

## Layout

| Directory | Contents |
|---|---|
| [`RecurLoop`](RecurLoop) | The `quantum.rl`, `qasm.rl` and `qft.rl` libraries, tests and examples |
| [`RecurLoop/ibm`](RecurLoop/ibm) | Compiling to OpenQASM 3 and running on an IBM quantum computer |
| [`RecurLoop/benchmark`](RecurLoop/benchmark) | Performance comparison: Python, NumPy, Rust and RecurLoop |
| [`materials`](materials) | Exam, problem sets and protocol diagrams (in Polish) |
| [`archive`](archive) | First implementations in Python, Rust and Qiskit (in Polish) |

## Quick start

```bash
git clone https://github.com/RecurLoop/RecurLoop.git
cd RecurLoop && make && cd ..

cd Algorytmy-Kwantowe/RecurLoop
./run.sh ../../RecurLoop/build/Release/bin/recurloop
```

The circuit language is described in [`RecurLoop/README.md`](RecurLoop/README.md).
