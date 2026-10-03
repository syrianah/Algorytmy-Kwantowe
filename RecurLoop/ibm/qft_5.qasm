// Obwód qft_5 wygenerowany przez RecurLoop z biblioteki qasm.rl
OPENQASM 3.0;
include "stdgates.inc";

qubit[3] r;
h r[0];
p(3.9269908169872414) r[0];
h r[1];
p(7.8539816339744828) r[1];
h r[2];
p(15.707963267948966) r[2];
swap r[0], r[2];
h r[0];
cp(-1.5707963267948966) r[0], r[1];
h r[1];
cp(-0.78539816339744828) r[0], r[2];
cp(-1.5707963267948966) r[1], r[2];
h r[2];
bit[3] wynik;
wynik[0] = measure r[0];
wynik[1] = measure r[1];
wynik[2] = measure r[2];
