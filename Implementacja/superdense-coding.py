from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot, randomQ, PauliX, PauliY, PauliZ
from complex import Complex
import numpy as np
import math

#Inicjalizacja Bramek
X = PauliX()
Y = PauliY()
Z = PauliZ()
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

#Pierwszy krok
X = np.kron(X, I)
first = np.tensordot(X, xy, axes=[1,0])
print(first)

#Drugi krok
second = np.tensordot(CNOT, first, axes=[1,0])
print(second)

#Trzeci krok
H = np.kron(H, I)
third = np.tensordot(H, second, axes=[1,0])
print(third)

#Pomiar
M0 = np.array([[Complex(1, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(0, 0)]])

M1 = np.array([[Complex(0, 0), Complex(0, 0)],
            [Complex(0, 0), Complex(1, 0)]])


M10 = np.kron(M1, M1)
P = np.tensordot(M10, third, axes=[1,0])
print(P)
