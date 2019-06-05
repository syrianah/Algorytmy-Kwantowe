from qubit import Qubit, tensordot, Hadamard, Cnot, Identity, PauliX, PauliY, PauliZ, M0, M1
from complex import Complex
import numpy as np
import math

#Inicjalizacja macierzy pomiaru
M0 = M0()
M1 = M1()

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
print("What you whant encode?")
opcja = input()
if opcja == '00':
    first = xy
elif opcja == '01':
    X = np.kron(X, I)
    print(X)
    first = np.tensordot(X, xy, axes=[1,0])
elif opcja == '10':
    Z = np.kron(Z, I)
    print(Z)
    first = np.tensordot(Z, xy, axes=[1,0])
elif opcja == '11':
    XZ = np.tensordot(X, Z, axes=[1,0])
    XZ = np.kron(XZ, I)
    print(XZ)
    first = np.tensordot(XZ, xy, axes=[1,0])
print(first)

#Drugi krok
second = np.tensordot(CNOT, first, axes=[1,0])
print(second)

#Trzeci krok
H = np.kron(H, I)
third = np.tensordot(H, second, axes=[1,0])
print(third)

if opcja == '00':
    M00 = np.kron(M0, M0)
    P = np.tensordot(M00, third, axes=[1,0])
elif opcja == '01':
    M01 = np.kron(M0, M1)
    P = np.tensordot(M01, third, axes=[1,0])
elif opcja == '10':
    M10 = np.kron(M1, M0)
    P = np.tensordot(M01, third, axes=[1,0])
elif opcja == '11':
    M11 = np.kron(M1, M1)
    P = np.tensordot(M11, third, axes=[1,0])

print(P)
