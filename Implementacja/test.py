from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot
from complex import Complex
import numpy as np
import math

Cnot = Cnot()
I = Identity()

q1 = Qubit(Complex(0, 0), Complex(1, 0))
q2 = Qubit(Complex(0, 0), Complex(1, 0))
q3 = Qubit(Complex(0, 0), Complex(1, 0))

Q = tensordot(q1, q2)
Q = np.kron(Q, q3.vector())
print(Q)

Cnot = np.kron(Cnot, I)
print(Cnot)

Q = np.tensordot(Cnot, Q, axes=[1,0])
print(Q)