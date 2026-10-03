// Obwód kontrola wygenerowany przez RecurLoop z biblioteki qasm.rl
OPENQASM 3.0;
include "stdgates.inc";

qubit psi;
ry(1.8586144017765862) psi;
p(2.1128175399482427) psi;
// expect psi == psi: po odwróceniu przygotowania pomiar musi dać 0
p(-2.1128175399482427) psi;
ry(-1.8586144017765862) psi;
bit[1] expect_psi;
expect_psi[0] = measure psi;
