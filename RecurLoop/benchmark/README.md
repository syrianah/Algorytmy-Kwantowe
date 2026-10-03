# Performance comparison: Python, NumPy, Rust and RecurLoop

The same state-vector simulator written four ways. All implementations
produce identical checksums, so they compute exactly the same thing.

## Results

Compute time in milliseconds (ms). 1000 ms is 1 second. Lower is faster.
Each test ran three times and the best time is shown.

| Implementation | Teleportation | 16 qubits | 20 qubits |
|---|---:|---:|---:|
| Python, pure | 2,392 ms | 2,386 ms | 64,649 ms |
| Python, NumPy | 22,118 ms | 184 ms | 1,633 ms |
| Rust, division and modulo | 65 ms | 40 ms | 904 ms |
| Rust, bitwise operators | 57 ms | 23 ms | 500 ms |
| **RecurLoop** | **77 ms** | **51 ms** | **1,115 ms** |

Teleportation is 100,000 teleportations on 3 qubits. The 16 and 20 qubit
columns are 5 layers of gates on a register of that size.

How many times slower than the fastest version, Rust with bitwise operators:

| Implementation | Teleportation | 16 qubits | 20 qubits |
|---|---:|---:|---:|
| Python, pure | 42× | 103× | 129× |
| Python, NumPy | 389× | 8.0× | 3.3× |
| Rust, division and modulo | 1.1× | 1.7× | 1.8× |
| **RecurLoop** | **1.3×** | **2.2×** | **2.2×** |

The RecurLoop process took about 3.1 s in total. About 1.9 s of that is
startup and compiling the program; the rest is the computation in the table.
Rust is compiled beforehand with a separate `rustc` command.

## Conclusions

- **RecurLoop is close to Rust on the same code.** It is only 18 to 27%
  slower than Rust using the same division-and-modulo workaround. Both
  generate machine code through LLVM.
- **The lack of bitwise operators costs almost half the performance.** On
  the layers, Rust with bitwise operators is 1.7 to 1.8 times faster than the
  division version. Once `&` and `>>` are added to RecurLoop, the simulator
  should get close to Rust.
- **Pure Python is 30 to 60 times slower than RecurLoop.** At 20 qubits it
  takes over a minute versus just over a second.
- **NumPy does not help with many small operations.** In teleportation,
  where the state has only 8 amplitudes, the overhead of NumPy calls makes it
  9 times slower than pure Python and 290 times slower than RecurLoop. At 20
  qubits, on the other hand, NumPy is only 1.5 times slower than RecurLoop.

## What is measured

**Teleportation ×100,000.** The full protocol on 3 qubits: a random state,
an entangled pair, Alice's measurement, Bob's corrections and a fidelity
check. Many small operations, so call overhead dominates.

**Layers.** A register of 16 or 20 qubits and 5 layers. Each layer is H and
RY gates on every qubit followed by a chain of CNOTs between neighbours. At
20 qubits that is a million amplitudes, so the speed of loops over memory
dominates.

**Algorithm.** Every version except NumPy walks over all amplitude indices,
tests the bits of the target and control qubits, and then updates a pair of
amplitudes. The NumPy version keeps the state as a 2×2×…×2 tensor and applies
a gate with a `tensordot` along the qubit's axis.

**The division variant.** RecurLoop has no bitwise operators, so bit k of i
is computed as `i / 2^k % 2`. Rust is measured in both variants to separate
the cost of this workaround from the quality of the compiler.

## Caveats

- The measurements come from a virtual machine, where repeats differ by ten
  to twenty percent. That is why the table shows the best of three times.
- The random number generators differ, so the distribution of teleportation
  results differs between languages. The layer checksums use no randomness.
- The NumPy version is typical but not the fastest possible. Hand-optimized
  NumPy, for example with slice indexing instead of `tensordot`, would be
  faster on large registers.

## Environment

| | |
|---|---|
| CPU | Intel Xeon @ 2.10 GHz, 4 virtual cores |
| OS | Linux x86-64 |
| Python | 3.11.15, NumPy 2.4.6 |
| Rust | rustc 1.97.0, `-C opt-level=3 -C target-cpu=native` |
| RecurLoop | commit `5534f94`, Release build with LLVM 22.1.8 |

## Running

```bash
pip install numpy
./run_benchmark.sh /path/to/RecurLoop/build/Release/bin/recurloop
```

The `REPEATS` variable sets the number of repeats, 3 by default. The whole
run takes about 5 minutes, mostly pure Python at 20 qubits.
