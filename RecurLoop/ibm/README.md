# Quantum protocols and algorithms on an IBM quantum computer

The same circuits written in our language can be simulated, or compiled to
OpenQASM 3 and run on a real IBM processor. The backend is chosen by the
included library: `quantum.rl` simulates and `qasm.rl` compiles.

| File | Contents |
|---|---|
| `circuits.rl` | The circuits in our language, without a choice of backend |
| `simulate.rl` | Simulates the circuits with the `quantum.rl` library |
| `generate_qasm.rl` | Compiles the circuits to `.qasm` files with the `qasm.rl` library |
| `*.qasm` | The generated OpenQASM 3 programs |
| `check_noise.py` | Runs on noise models of IBM processors, no account needed |
| `run_ibm.py` | Runs on a real IBM processor |
| `common.py` | Loading and scoring shared by both scripts |
| `requirements.txt` | Python packages |

## Circuits

- **`teleportation`** is a dynamic circuit. Alice measures two qubits
  mid-circuit and the processor immediately applies the X and Z corrections
  to Bob's qubit.
- **`teleportation_deferred`** gives the same result without mid-circuit
  measurements. The corrections are quantum-controlled through CNOT and CZ,
  and the measurements come at the end. It runs on any processor.
- **`control`** only prepares and undoes a state on one qubit. It shows how
  many errors the hardware adds on its own, without teleportation.
- **`superdense_00`, `superdense_01`, `superdense_10`, `superdense_11`** are
  superdense coding. Alice sends Bob two bits by handing him one qubit of a
  shared entangled pair. Each circuit sends a different message, and Bob's
  bits go to the `decoded1` and `decoded2` registers.
- **`chsh_00`, `chsh_01`, `chsh_10`, `chsh_11`** are the CHSH game. Alice
  gets question x, Bob question y, and they win when their answers a and b
  satisfy a XOR b = x AND y. Circuit `chsh_XY` plays with questions x = X and
  y = Y. Classically at most 75% of games can be won; with an entangled pair,
  85.4%. The average win rate over the four circuits gives the value
  S = 8 * average - 4. Classically S <= 2; quantum mechanics allows up to
  2 sqrt(2) = 2.83.
- **`qft_0` to `qft_7`** are the quantum Fourier transform from the
  `../qft.rl` library, in the role it plays in phase estimation. The number K
  is stored only in the phases of three qubits, without entanglement. The
  inverse QFT turns the phases into a number, and measuring the `result`
  register should give K. Guessing would be right 12.5% of the time.
- **`grover2_0` to `grover2_3` and `grover3_0` to `grover3_7`** are Grover's
  search from the `../grover.rl` library. The oracle hides the number K and
  only flips the sign of |K>. On two qubits one iteration finds K with
  certainty; on three qubits two iterations find it 94.5% of the time.
  Measuring the `found` register should give K. Guessing would be right 25%
  or 12.5% of the time.

Bob's state cannot be read out directly on hardware. So `expect bob == psi`
undoes the preparation of psi on Bob's qubit and measures it into the bit
`expect_bob`. A successful teleportation always gives 0. If Bob's state were
completely random, 0 would come up in only half of the runs.

In superdense coding, success means Bob decoded exactly the bits that were
sent. Guessing, he would be right 25% of the time. The outcome of each of
these circuits is known in advance, so the Qiskit compiler could remove the
entanglement and leave only X gates before the measurement. The
`barrier alice, bob` statements between preparing the pair, Alice's encoding
and Bob's decoding prevent that.

## Step by step

**1. Generate the QASM files.** The generated files are already in the repo.
The random seed is fixed, so regenerating gives the same files.

```bash
recurloop --file generate_qasm.rl
```

**2. Install the Python packages.**

```bash
pip install -r requirements.txt
```

**3. Check on noise models.** No account needed.

```bash
python3 check_noise.py
```

**4. Save the API key.** You find the key on your IBM Quantum Platform
account page. It is saved once, locally on your computer. Never put it in
files in the repo.

```python
from qiskit_ibm_runtime import QiskitRuntimeService
QiskitRuntimeService.save_account(
    channel="ibm_quantum_platform", token="YOUR_API_KEY", set_as_default=True)
```

Instead of saving the account, you can set the `IBM_QUANTUM_TOKEN`
environment variable to the key, and optionally `IBM_QUANTUM_INSTANCE`.

**5. Check the connection.** Without the `--submit` flag the script only
picks a processor and compiles the circuits, without submitting anything.

```bash
python3 run_ibm.py
```

**6. Submit the job.**

```bash
python3 run_ibm.py --submit
```

All circuits are submitted by default. `--set teleportation`,
`--set superdense`, `--set chsh`, `--set qft` or `--set grover` picks just one
group. `check_noise.py` takes the same `--set` flag.

The script prints the job ID and waits for the result. The queue can take
from minutes to hours. The results can also be fetched later:

```bash
python3 run_ibm.py --job JOB_ID
```

## What to expect

Results on noise models, 4000 runs of each circuit:

| Processor | teleportation | teleportation_deferred | control |
|---|---:|---:|---:|
| Brisbane | 94.8% | 96.4% | 99.5% |
| Torino | 96.9% | 97.9% | 99.8% |
| Fez | 98.6% | 98.7% | 100.0% |

Superdense coding on the same models, success for each message:

| Processor | 00 | 01 | 10 | 11 |
|---|---:|---:|---:|---:|
| Brisbane | 96.3% | 95.2% | 96.8% | 95.2% |
| Torino | 97.9% | 97.2% | 97.9% | 97.2% |
| Fez | 99.3% | 98.4% | 98.7% | 97.9% |

The CHSH game on the same models, wins for questions x y and the S value:

| Processor | 00 | 01 | 10 | 11 | S |
|---|---:|---:|---:|---:|---:|
| Brisbane | 83.9% | 84.0% | 82.2% | 83.4% | 2.670 |
| Torino | 84.1% | 84.8% | 83.2% | 84.4% | 2.729 |
| Fez | 84.8% | 83.8% | 84.5% | 84.7% | 2.754 |

The QFT on the same models, fraction of runs that read back the number K:

| Processor | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | Average |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Brisbane | 91.1% | 90.7% | 90.4% | 91.8% | 91.5% | 90.3% | 90.7% | 92.1% | 91.1% |
| Torino | 94.0% | 93.6% | 94.0% | 93.0% | 93.5% | 91.9% | 93.7% | 92.9% | 93.3% |
| Fez | 97.2% | 95.9% | 95.5% | 95.0% | 96.2% | 95.6% | 95.7% | 94.0% | 95.6% |

After compilation the QFT circuits have 9 two-qubit gates each, more than
the others, hence the lower results.

Grover's search on the same models, fraction of runs that found the marked
number K:

| Processor | 2 qubits: 0 | 1 | 2 | 3 |
|---|---:|---:|---:|---:|
| Brisbane | 96.4% | 95.8% | 95.5% | 95.3% |
| Torino | 97.7% | 97.4% | 97.4% | 97.5% |
| Fez | 99.4% | 98.6% | 99.0% | 97.7% |

| Processor | 3 qubits: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | Average |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Brisbane | 72.8% | 72.6% | 75.0% | 76.1% | 72.7% | 72.5% | 75.1% | 75.0% | 74.0% |
| Torino | 81.9% | 80.7% | 79.3% | 80.5% | 81.2% | 81.5% | 80.3% | 79.5% | 80.6% |
| Fez | 83.7% | 82.9% | 83.2% | 83.0% | 82.3% | 82.7% | 82.3% | 81.7% | 82.7% |

On two qubits the search has only 2 two-qubit gates: the CZ of the oracle and
the CZ of the diffusion. On three qubits each of the four CCZ gates becomes
six CNOTs, and three qubits on the processor are never all connected to each
other, so the compiler adds swaps: 37 two-qubit gates in all. Even so the
ideal result is 94.5%, not 100%.

Results on real hardware will probably be somewhat lower:

- **The models come from older calibrations.** The processor's current
  parameters may be better or worse.
- **The model probably does not fully capture the wait for a mid-circuit
  measurement in a dynamic circuit.** On hardware Bob's qubit waits while the
  processor measures Alice's qubits and makes the decision. It loses
  coherence meanwhile, so `teleportation` may do worse than
  `teleportation_deferred`.
- **The result depends on the random psi state.** Some states are more
  sensitive to particular hardware errors.

Any result clearly above 50% shows that teleportation works. The difference
between `control` and the teleportation circuits is the cost of the protocol
itself.

## Results on real hardware

Summary. The last column is the random result or the best one possible
without entanglement. All jobs together took 28 seconds of processor time.

| Algorithm | Processor | Result | Without quantum advantage |
|---|---|---:|---:|
| Teleportation | `ibm_kingston` | 94.5% | 50% |
| Superdense coding | `ibm_fez` | 96.8% | 25% |
| CHSH game | `ibm_fez` | S = 2.70 | S ≤ 2 |
| QFT, reading a number from phases | `ibm_fez` | 90.5% | 12.5% |

The jobs ran before the project was translated to English, when the circuits
and registers had Polish names (for example `teleportacja`, `alicja`,
`odczyt1`, `wynik`). The gates are identical to the current `.qasm` files,
and `run_ibm.py --job` reads both the old and the new register names.

### Teleportation

On 3 October 2026 the circuits ran on the `ibm_kingston` processor
(156 qubits), 4000 runs of each circuit. Job `db04selj371s73dnt1p0` took
5 seconds of processor time.

| Circuit | Success on `ibm_kingston` |
|---|---:|
| teleportation | 94.5% |
| teleportation_deferred | 96.4% |
| control | 98.9% |

Results of the `teleportation` circuit broken down by Alice's measurements:

| m1 m2 | Runs | Correction on Bob's qubit | Success |
|---|---:|---|---:|
| 00 | 1023 | none | 92.5% |
| 01 | 1019 | X | 95.2% |
| 10 | 1042 | Z | 94.5% |
| 11 | 916 | X and Z | 95.7% |

What this shows:

- **Teleportation works on real hardware.** The psi state reaches Bob in
  about 95% of cases. The standard deviation at 4000 runs is about 0.4
  percentage points.
- **Measurement-controlled corrections work.** Each of Alice's four results
  comes up in about 25% of the runs, and in all four cases Bob gets the right
  state. Without the X and Z corrections, three of the four branches would
  give a result close to random.
- **The dynamic circuit does worse than the deferred one** by about 2 points,
  even though it has fewer two-qubit gates (2 versus 7). That is the cost of
  Bob's qubit waiting for the measurement and the processor's decision,
  mentioned above.
- **About 1.1% of errors come from readout alone.** That is the error of the
  `control` circuit, in which the compiler removed the preparation and its
  inverse as cancelling out, leaving only the measurement.
- **The result is closest to the Brisbane model**, the weakest of the noise
  models, even though Kingston is a newer-generation processor.

### Superdense coding

The same day the four superdense coding circuits ran on the `ibm_fez`
processor (156 qubits), 4000 runs each. Job `db0533lj371s73dntdm0` took
6 seconds of processor time.

| Message sent | Bob read 00 | 01 | 10 | 11 | Success | Fez model |
|---|---:|---:|---:|---:|---:|---:|
| 00 | **3861** | 63 | 58 | 18 | 96.5% | 99.3% |
| 01 | 40 | **3918** | 10 | 32 | 98.0% | 98.4% |
| 10 | 76 | 15 | **3822** | 87 | 95.5% | 98.7% |
| 11 | 10 | 58 | 53 | **3879** | 97.0% | 97.9% |

What this shows:

- **One qubit carries two bits.** Bob decodes the right message in 96.8% of
  runs on average. Guessing, he would be right 25% of the time.
- **Errors usually affect a single bit.** A read that differs from the
  message in both bits at once happens 10 to 18 times per 4000 runs. That
  fits independent gate and readout errors on each qubit.
- **The hardware did 0.4 to 3.2 points worse than the Fez model.** The model
  comes from an older calibration, and the processor's parameters change from
  day to day.
- **The barriers are necessary.** Without `barrier alice, bob` the compiler
  would turn each of these circuits into X gates before the measurement. The
  result would then be almost perfect, but without entanglement, so it would
  prove nothing.

### The CHSH game

The same day the four CHSH game circuits ran on the `ibm_fez` processor,
4000 runs each. Job `db05ba492g1c7399tjb0` took 6 seconds of processor time.

| Questions x y | Wins on `ibm_fez` | Fez model | Ideal |
|---|---:|---:|---:|
| 00 | 84.3% | 84.8% | 85.4% |
| 01 | 84.4% | 83.8% | 85.4% |
| 10 | 83.9% | 84.5% | 85.4% |
| 11 | 82.6% | 84.7% | 85.4% |
| **S** | **2.704** | 2.754 | 2.828 |

What this shows:

- **The Bell inequality is violated.** S = 2.704 ± 0.023, which is 0.70
  above the classical bound of 2. That is over 30 standard deviations, so the
  result is not a statistical fluke.
- **Alice and Bob won 83.8% of the games on average.** No classical strategy
  gives more than 75%, even if the players agree on shared random bits before
  the game.
- **The result is close to ideal despite the noise.** Noise lowered S from
  2.828 to 2.704, by about 4%. The circuit has only one two-qubit gate.
- **The same caveat as for any such test on a single chip.** Alice's and
  Bob's qubits sit next to each other, and the questions are written into the
  circuit before it runs. The measurement therefore does not close the
  locality loophole the way experiments with distant detectors do, but it
  does show correlations that classical bits cannot produce.

### The quantum Fourier transform

The same day the eight QFT circuits ran on the `ibm_fez` processor, 4000 runs
each. Job `db05kfc92g1c7399ttag` took 11 seconds of processor time.

| Stored number K | Read K | Fez model | One-bit error | Larger error |
|---|---:|---:|---:|---:|
| 0 (000) | 94.7% | 97.2% | 116 | 98 |
| 1 (001) | 92.0% | 95.9% | 188 | 131 |
| 2 (010) | 90.3% | 95.5% | 236 | 153 |
| 3 (011) | 88.0% | 95.0% | 265 | 213 |
| 4 (100) | 92.6% | 96.2% | 211 | 86 |
| 5 (101) | 90.8% | 95.6% | 254 | 115 |
| 6 (110) | 88.9% | 95.7% | 302 | 140 |
| 7 (111) | 86.5% | 94.0% | 357 | 185 |
| **Average** | **90.5%** | 95.6% | | |

The last two columns are the number of runs out of 4000 in which the read
differed from K in one bit or in more than one bit.

What this shows:

- **The inverse QFT reads the number from the phases in 90.5% of runs.**
  Guessing one of eight numbers would be right 12.5% of the time. Each of the
  eight circuits gives the right number many times more often than any other.
- **The more ones in K, the worse.** On average 94.7% for the number with no
  ones, 91.6% for numbers with one, 89.2% with two and 86.5% with three,
  roughly 2.7 points per one. For K = 7 every one-bit error is a 1 turning
  into 0 (357 cases), and for K = 0 a 0 turning into 1 (116). A qubit in
  state |1> drops to |0> during measurement more often than the other way
  round, because |1> has higher energy and decays with time T1.
- **The hardware did about 5 points worse than the Fez model.** That is the
  largest gap of all the circuits. The QFT circuits have the most two-qubit
  gates (9) and are the deepest, so the difference between the old
  calibration in the model and the processor's state today adds up the most.

## Account and limits

The free IBM Quantum plan gives a limited amount of time on real processors
each month, 10 minutes on the Open plan. This set uses little of it: all 19
circuits at 4000 runs each took 28 seconds together (5 seconds for
teleportation, 6 each for superdense coding and CHSH, 11 for the QFT). The
`--shots` flag sets the number of runs, and `--set` submits just one group of
circuits.
