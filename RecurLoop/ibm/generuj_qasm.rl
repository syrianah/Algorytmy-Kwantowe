// Kompiluje obwody z obwody.rl do plików OpenQASM 3 w bieżącym katalogu.
// Uruchomienie z katalogu ibm:
//   recurloop --file generuj_qasm.rl

include "../qasm.rl"
include "../qft.rl"
include "obwody.rl"

// Stałe ziarno: te same kąty stanu psi przy każdym generowaniu.
seed 2026

teleportacja()
teleportacja_odroczona()
kontrola()
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
