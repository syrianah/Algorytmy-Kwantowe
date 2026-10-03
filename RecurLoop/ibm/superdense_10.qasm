// Obwód superdense_10 wygenerowany przez RecurLoop z biblioteki qasm.rl
OPENQASM 3.0;
include "stdgates.inc";

qubit alicja;
qubit bob;
h alicja;
cx alicja, bob;
barrier alicja, bob;
z alicja;
barrier alicja, bob;
cx alicja, bob;
h alicja;
bit[1] odczyt1;
odczyt1[0] = measure alicja;
bit[1] odczyt2;
odczyt2[0] = measure bob;
