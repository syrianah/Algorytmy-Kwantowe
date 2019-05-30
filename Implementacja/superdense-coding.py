from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot, randomQ, PauliX
from complex import Complex
import numpy as np
import math

#Inicjalizacja Bramek
X = PauliX()
H = Hadamard()
CNOT = Cnot()
I = Identity()

#Splątany Qubity Alicji i Boba
x = Qubit(Complex(1, 0), Complex(0, 0))
y = Qubit(Complex(1, 0), Complex(0, 0))

x = x * H
xy = tensordot(x, y)
xy = np.tensordot(CNOT, xy, axes=[1,0])
print("splątany = ", xy)

X = np.tensordot(X, I, axes=[1,0])
first = np.kron(X, xy)
print(first)

second = np.tensordot(CNOT, first, axes=[1,0])
