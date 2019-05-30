from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot, randomQ
from complex import Complex
import numpy as np
import math

Cnot = Cnot()
I = Identity()

q1 = randomQ()
q2 = Qubit(Complex(1/math.sqrt(2), 0), Complex(1/math.sqrt(2), 0))
q3 = randomQ()

Q = tensordot(q1, q3)
# Q = np.kron(Q, q3.vector())
print(Q)

# Cnot = np.kron(Cnot, I)
# print(Cnot)
#
# Q = np.tensordot(Cnot, Q, axes=[1,0])
# print(Q)
