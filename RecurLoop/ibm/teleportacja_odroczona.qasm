// Obwód teleportacja_odroczona wygenerowany przez RecurLoop z biblioteki qasm.rl
OPENQASM 3.0;
include "stdgates.inc";

qubit psi;
qubit alicja;
qubit bob;
ry(0.89459177757054509) psi;
p(0.098095252614989734) psi;
h alicja;
cx alicja, bob;
cx psi, alicja;
h psi;
cx alicja, bob;
cz psi, bob;
// expect bob == psi: po odwróceniu przygotowania pomiar musi dać 0
p(-0.098095252614989734) bob;
ry(-0.89459177757054509) bob;
bit[1] expect_bob;
expect_bob[0] = measure bob;
bit[1] m1;
m1[0] = measure psi;
bit[1] m2;
m2[0] = measure alicja;
