// Obwód chsh_11 wygenerowany przez RecurLoop z biblioteki qasm.rl
OPENQASM 3.0;
include "stdgates.inc";

qubit alicja;
qubit bob;
h alicja;
cx alicja, bob;
barrier alicja, bob;
ry(-1.5707963267948966) alicja;
ry(0.78539816339744828) bob;
bit[1] a;
a[0] = measure alicja;
bit[1] b;
b[0] = measure bob;
