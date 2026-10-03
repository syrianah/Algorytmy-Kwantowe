// Compiles the circuits from circuits.rl to OpenQASM 3 files in the current
// directory.
// Run from the ibm directory:
//   recurloop --file generate_qasm.rl

include "../qasm.rl"
include "../qft.rl"
include "../grover.rl"
include "circuits.rl"

// Fixed seed: the same psi angles on every generation.
seed 2026

teleportation()
teleportation_deferred()
control()
superdense_00()
superdense_01()
superdense_10()
superdense_11()
chsh_00()
chsh_01()
chsh_10()
chsh_11()
qft_0()
qft_1()
qft_2()
qft_3()
qft_4()
qft_5()
qft_6()
qft_7()
grover2_0()
grover2_1()
grover2_2()
grover2_3()
grover3_0()
grover3_1()
grover3_2()
grover3_3()
grover3_4()
grover3_5()
grover3_6()
grover3_7()
