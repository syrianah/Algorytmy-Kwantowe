from qubit import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, randomQ, M0, M1, RY
from complex import Complex
import numpy as np
import math
import random


pi = math.pi

x = random.randint(0, 1)
y = random.randint(0, 1)


# Inicjalizacja macierzy pomiaru
M0 = M0()
M1 = M1()

# Inicjalizacja Bramek
H = Hadamard()
CNOT = Cnot()
I = Identity()
RY_pi_4 = RY(pi/4)
RY_pi_8 = RY(pi/8)

# Splątany Qubity Alicji i Boba
qx = Qubit(Complex(1, 0), Complex(0, 0))
qy = Qubit(Complex(1, 0), Complex(0, 0))

qx = qx * H
xy = tensordot(qx, qy)
first = np.tensordot(CNOT, xy, axes=[1, 0])
# print("splątany = ", xy)

RYGATE = np.kron(RY(pi/4), RY(pi/8))
# print(RY)
second = np.tensordot(RYGATE, first, axes=[1, 0])
# print(second)
# print(x, y)


# Alice
if x == 0:
    M01 = np.kron(M0, M1)
    P = np.tensordot(M01, second, axes=[1, 0])
elif x == 1:
    RY_pi_4 = np.kron(RY(pi/4), I)
    third = np.tensordot(RY_pi_4, second, axes=[1, 0])
    # print("drugi = ", second)
    M01 = np.kron(M0, M1)
    P = np.tensordot(M01, third, axes=[1, 0])

# Bob
if y == 0:
    RY_pi_8 = np.kron(RY(pi/8), I)
    thirdB = np.tensordot(RY_pi_8, second, axes=[1, 0])
    # print("drugi = ", secondB)
    M01 = np.kron(M0, M1)
    PB = np.tensordot(M01, second, axes=[1, 0])
elif y == 1:
    RY_pi_8 = np.kron(RY(-pi/8), I)
    thirdB = np.tensordot(RY_pi_8, second, axes=[1, 0])
    # print("drugi = ", secondB)
    M01 = np.kron(M0, M1)
    PB = np.tensordot(M01, thirdB, axes=[1, 0])


print(P)
print(PB)
print(x, y)
