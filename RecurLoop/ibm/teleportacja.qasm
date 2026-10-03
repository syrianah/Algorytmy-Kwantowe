// Obwód teleportacja wygenerowany przez RecurLoop z biblioteki qasm.rl
OPENQASM 3.0;
include "stdgates.inc";

qubit psi;
qubit alicja;
qubit bob;
ry(1.4026154045417409) psi;
p(1.5719432478228681) psi;
h alicja;
cx alicja, bob;
cx psi, alicja;
h psi;
bit[1] m1;
m1[0] = measure psi;
bit[1] m2;
m2[0] = measure alicja;
if (m2[0]) {
    x bob;
}
if (m1[0]) {
    z bob;
}
// expect bob == psi: po odwróceniu przygotowania pomiar musi dać 0
p(-1.5719432478228681) bob;
ry(-1.4026154045417409) bob;
bit[1] expect_bob;
expect_bob[0] = measure bob;
