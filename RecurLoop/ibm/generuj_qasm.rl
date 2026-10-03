// Kompiluje obwody z obwody.rl do plików OpenQASM 3 w bieżącym katalogu.
// Uruchomienie z katalogu ibm:
//   recurloop --file generuj_qasm.rl

include "../qasm.rl"
include "obwody.rl"

// Stałe ziarno: te same kąty stanu psi przy każdym generowaniu.
seed 2026

teleportacja()
teleportacja_odroczona()
kontrola()
