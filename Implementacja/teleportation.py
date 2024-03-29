from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, RCnot, randomQ, PauliX, M0, M1
from complex import Complex
import numpy as np
import math
import time

#Inicjalizacja macierzy pomiaru
M0 = M0()
M1 = M1()

#Inicjalizacja Bramek
X = PauliX()
H = Hadamard()
CNOT = Cnot()
RCNOT = RCnot()
I = Identity()

start = time.time()

#Splątany Qubity Alicji i Boba
x = Qubit(Complex(1, 0), Complex(0, 0))
y = Qubit(Complex(1, 0), Complex(0, 0))

x = x * H
print("x", x)
xy = tensordot(x, y)
print("xy", xy)
xy = np.tensordot(CNOT, xy, axes=[1,0])
print("splątany = ", xy)

#Qubit do teleportowania
psi = randomQ()
# psi = Qubit(Complex(0, 0), Complex(1, 0))
print("Qubit po stronie Alicji")
print("psi = ", psi.alpha, psi.beta)

#Pierwszy Krok
# first = np.kron(xy, psi.vector())
first = np.kron(psi.vector(), xy)
print("pierwszy = ", first)

#Drugi Krok
Cnot = np.kron(CNOT, I)
# print(Cnot)
second = np.tensordot(Cnot, first, axes=[1,0])
print("drugi = ", second)

#Trzeci Krok
H = np.kron(H, I)
H = np.kron(H, I)
# print(H)
third = np.tensordot(H, second, axes=[1,0])
print("trzeci = ", third)

#Pomiar
M01 = np.kron(M0, M1)
M010 = np.kron(M01, I)
# print(M010)

P = np.tensordot(M010, third, axes=[1,0])
print(P)

#Przypisanie
alpha = P[2] * 2
beta = P[3] * 2
# print(alpha, beta)

#Qubit po teleportacji
psi = Qubit(alpha, beta)
psi = psi * X
print("Qubit po stronie Boba")
print("psi = ", psi.alpha, psi.beta)
end = time.time()
print("Ukończono w czasie:", (end - start) * 1000)
