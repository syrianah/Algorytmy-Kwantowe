import numpy as np
import math
import random

from complex import Complex, PolarToComplex
from vector import Vector


def P0(qubit):
    return abs(qubit.alpha)**2


def P1(qubit):
    return abs(qubit.beta)**2


def Qubit_after_measure(qubit):
    if P0(qubit) > P1(qubit):
        alfa = qubit.alpha/abs(qubit.alpha)
        return Qubit(alfa, Complex(0, 0))
    else:
        beta = qubit.beta/abs(qubit.beta)
        return Qubit(Complex(0, 0), beta)


def Measure(qubit):
    if P0(qubit) > P1(qubit):
        P = random.uniform(0, 1)
        if P < P0(qubit):
            return 0
        else:
            return 1
    elif P0(qubit) < P1(qubit):
        P = random.uniform(0, 1)
        if P < P1(qubit):
            return 1
        else:
            return 0
    else:
        P = random.uniform(0, 1)
        if P < 0.5:
            return 0
        else:
            return 1


def tensordot(a, b):
    return np.kron(a.vector(), b.vector())
    # return np.tensordot(a.vector(), b.vector(), axes=0)


def randomQ():
    a = random.uniform(-1, 1)
    b = random.uniform(-1, 1)
    while a**2 > 1 - b**2:
        a = random.uniform(-1, 1)
        b = random.uniform(-1, 1)
    alpha = Complex(a, b)
    # print(abs(alpha**2))
    abs_beta = math.sqrt(1 - abs(alpha)**2)
    # print(abs_beta**2)
    c = random.uniform(-1, 1)
    d = abs_beta**2 - c
    while c > 1 - a**2:
        c = random.uniform(-1, 1)
    d = (abs_beta**2 - c**2)**0.5
    beta = Complex(c, d)
    return Qubit(alpha, beta)


def M0():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0)]])


def M1():
    return np.array([[Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(1, 0)]])


def Identity():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(1, 0)]])


def Hadamard():
    return np.array([[Complex(1/np.sqrt(2), 0), Complex(1/np.sqrt(2), 0)],
                     [Complex(1/np.sqrt(2), 0), Complex(-1/np.sqrt(2), 0)]])


def PauliX():
    return np.array([[Complex(0, 0), Complex(1, 0)],
                     [Complex(1, 0), Complex(0, 0)]])


def PauliY():
    return np.array([[Complex(0, 0), Complex(0, -1)],
                     [Complex(0, 1), Complex(0, 0)]])


def PauliZ():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(-1, 0)]])


def Sgate():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 1)]])


def SNgate():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, -1)]])


def Tgate():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), PolarToComplex(1, -45)]])


def TNgate():
    return np.array([[Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), PolarToComplex(1, 45)]])


def Cnot():
    return np.array([[Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(1, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(0, 0)]])


def RCnot():
    return np.array([[Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0),
                      Complex(0, 0), Complex(1, 0)],
                     [Complex(0, 0), Complex(0, 0),
                      Complex(1, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0)]])


def RX(qubit, phi):
    gate = np.array([[Complex(math.cos(phi/2), 0), Complex(0, math.sin(phi/2))],
                     [Complex(0, math.sin(phi/2)), Complex(math.cos(phi/2), 0)]])

    alpha = gate[0, 0] * qubit.alpha + gate[0, 1] * qubit.beta
    beta = gate[1, 0] * qubit.alpha + gate[1, 1] * qubit.beta
    qubit.update_state(alpha, beta)
    return Qubit(qubit.alpha, qubit.beta)


def RY(phi):
    return np.array([[Complex(math.cos(phi/2), 0), Complex(0, math.sin(phi/2)*1)],
                     [Complex(0, math.sin(phi/2)*(-1)), Complex(math.cos(phi/2), 0)]])

    # alpha = gate[0, 0] * qubit.alpha + gate[0, 1] * qubit.beta
    # beta = gate[1, 0] * qubit.alpha + gate[1, 1] * qubit.beta
    # qubit.update_state(alpha, beta)
    # return Qubit(qubit.alpha, qubit.beta)


def RZ(qubit, phi):
    gate = np.array([[Complex(math.cos(phi/2), math.sin(phi/2)), Complex(0, 0)],
                     [Complex(0, 0), Complex(math.cos(phi/2), math.sin(phi/2)*(-1))]])

    alpha = gate[0, 0] * qubit.alpha + gate[0, 1] * qubit.beta
    beta = gate[1, 0] * qubit.alpha + gate[1, 1] * qubit.beta
    qubit.update_state(alpha, beta)
    return Qubit(qubit.alpha, qubit.beta)


def Toffoli():
    return np.array([[Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0), Complex(
                         0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(0, 0), Complex(
                         0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(
                         0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(
                         1, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(
                         0, 0), Complex(1, 0), Complex(0, 0), Complex(0, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(
                         0, 0), Complex(0, 0), Complex(0, 0), Complex(1, 0)],
                     [Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(0, 0), Complex(1, 0), Complex(0, 0)]])


class Qubit:
    def __init__(self, alpha, beta):
        if 0.999999998 <= abs(alpha)**2 + abs(beta)**2 <= 1.00000001:
            self.alpha = alpha
            self.beta = beta
        else:
            print('Error')

    def __mul__(self, gate):
        alpha = gate[0, 0] * self.alpha + gate[0, 1] * self.beta
        beta = gate[1, 0] * self.alpha + gate[1, 1] * self.beta
        return Qubit(alpha, beta)
    
    def __str__(self) -> str:
        return f"|Ψ> = {self.alpha}|0> + {self.beta}|1>"

    def vector(self):
        return [self.alpha, self.beta]


m1 = np.array([[Complex(1, 0), Complex(0, 0)],
               [Complex(0, 0), Complex(0, 0)]])

m2 = np.array([[Complex(0, 0), Complex(0, 0)],
               [Complex(0, 0), Complex(1, 0)]])

# print(0.4677056485736148 + 0.5322943514263851)
# a = Complex(1/np.sqrt(2), 0)
# a = Complex(a, 0)
# # print(a**2+a**2)
# # print(a)
# q = Qubit(a, a)
# print(Measure(q))
# qM = Qubit_after_measure(q)
# print(qM.alpha)
# print(qM.beta)
# # q1 = Qubit.randomQ()
# q1 = randomQ()

# print(q1.alpha)
# print(q1.beta)
# print("-----------")
# print(q1.alpha)
# print(q1.beta)

H = Hadamard()
PX = PauliX()
PY = PauliY()
# print(PY)
# print(PY[0, 1])
PZ = PauliZ()
SG = Sgate()
TG = Tgate()
SNG = SNgate()
TNG = TNgate()
CNOT = Cnot()
RCNOT = RCnot()
# print(RCNOT)

# Odwrotny CNOT
Hdot = np.kron(H, H)
# print(Hdot)
# print(CNOT)

HdotCnot = np.tensordot(CNOT, Hdot, axes=[0, 1])
# print(HdotCnot)

ReverseCnot = np.tensordot(HdotCnot, Hdot, axes=[0, 1])
# print(ReverseCnot)

# new_qX = q1 * PX
# print(new_qX.alpha)
# print(new_qX.beta)
# print(Measure(new_qX))

# new_qX = new_qH * PX
# new_qY = new_qX * PY
# print(Measure(new_qY))
# print(new_qH.alpha)
# print(new_qH.beta)
# print(new_qX.alpha)
# print(new_qX.beta)
# print(new_qY.alpha)
# print(new_qY.beta)

# Tg = q * PZ
# print(Tg.alpha)
# print(Tg.beta)

# TNrand = q1 * TNG
# print(TNrand.alpha)
# print(TNrand.beta)

# print(Complex(0, -1) * Complex(1, 0))

# q1 = Qubit(Complex(0, 0), Complex(1, 0))
# q2 = Qubit(Complex(1, 0), Complex(0, 0))

# newq1 = q1 * H
# newq2 = q2 * H

# print(newq1.alpha, newq1.beta)

# tensor = tensordot(newq2, newq1)
# print(tensor)

# Hdot = np.kron(H, H)

# print(Hdot)
# print(CNOT)
# HdotCnot = np.tensordot(CNOT, Hdot, axes=[0,1])
# print(HdotCnot)

# ReverseCnot = np.tensordot(HdotCnot, Hdot, axes=[0,1])

# print(ReverseCnot)
