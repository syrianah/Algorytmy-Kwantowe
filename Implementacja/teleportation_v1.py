from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot
from complex import Complex
import numpy as np
import math

#Inicjalizacja Bramek
H = Hadamard()
CNOT = Cnot()
RCNOT = RCnot()
I = Identity()

#Splątany Qubity Alicji i Boba
x = Qubit(Complex(1, 0), Complex(0, 0))
y = Qubit(Complex(1, 0), Complex(0, 0))

x = x * H
xy = tensordot(x, y)
xy = np.tensordot(CNOT, xy, axes=[1,0])
print(xy)

#Qubit do teleportowania
psi = Qubit(Complex(0,0), Complex(1,0))
# print(psi.alpha, psi.beta)

#Pierwszy Krok
first = np.kron(xy, psi.vector())
# print(first)

#Drugi Krok
Cnot = np.kron(CNOT, I)
second = np.tensordot(Cnot, first, axes=[1,0])
# print(second)

#Trzeci Krok
H = np.kron(H, I)
H = np.kron(H, I)
# print(H)
third = np.tensordot(H, second, axes=[1,0])
print(third)