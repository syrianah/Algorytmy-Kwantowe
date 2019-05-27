from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot, randomQ
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
print("splątany = ", xy)

#Qubit do teleportowania
psi = randomQ()
# psi = Qubit(Complex(0, 0), Complex(1, 0))
print("psi = ", psi.alpha, psi.beta)

#Pierwszy Krok
first = np.kron(psi.vector(), xy)
print("pierwszy = ", first)

#Drugi Krok
Cnot = np.kron(CNOT, I)
second = np.tensordot(Cnot, first, axes=[1,0])
print("drugi = ", second)

#Trzeci Krok
H = np.kron(H, I)
H = np.kron(H, I)
# print(H)
third = np.tensordot(H, second, axes=[1,0])
print("trzeci = ", third)

#Pomiar
M = np.array([[Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)]])

# P = np.tensordot(third, third, axes=[1,0])
# print(P)
P = np.dot(third, third)
# print(P)

# P = (1 - abs(P)**2)/2
# print("wynik", P)

# q1 = Qubit(third[0], third[1])
# print(q1.alpha, q1.beta)