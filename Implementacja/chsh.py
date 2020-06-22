from qubitNew import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, randomQ, M0, M1, RY
# from complex import Complex
import numpy as np
import random as rand

N = 100


def qAlice_output(strategy, inp):
    if(strategy == 1):
        return 0

    elif(strategy == 2):
        return rand.uniform(0, 2*np.pi)

    elif(strategy == 3):
        if(inp == 0):
            return 0
        elif(inp == 1):
            return np.pi/2

    else:
        print("INVALID choice")
        return 100


def qBob_output(strategy, inp):
    if(strategy == 1):
        return 0

    elif(strategy == 2):
        return rand.uniform(0, 2*np.pi)

    elif(strategy == 3):
        if(inp == 0):
            return np.pi/4
        elif(inp == 1):
            return -np.pi/4

    else:
        print("INVALID choice")
        return 100


# Inicjalizacja macierzy pomiaru
M0 = M0()
M1 = M1()

# Inicjalizacja Bramek
H = Hadamard()
CNOT = Cnot()
I = Identity()


# Alice's strategy
qA_st = int(input(
    'select the quantum strategy for Alice, input 1,2 or 3 to pick one of the strategies listed above: '))

# Bob's strategy
qB_st = int(input(
    'select the quantum strategy for Bob, input 1,2 or 3 to pick one of the strategies listed above: '))

# Start game
x = rand.randint(0, 1)
y = rand.randint(0, 1)


# Splątany Qubity Alicji i Boba
qx = Qubit(complex(1, 0), complex(0, 0))
qy = Qubit(complex(1, 0), complex(0, 0))

qx = qx * H
xy = tensordot(qx, qy)
# first = np.tensordot(CNOT, xy, axes=[1, 0])
first = np.matmul(xy, CNOT)
print("splątany = ", first)

theta = qAlice_output(qA_st, x)  # fixes Alice's rotation for her qubit
phi = qBob_output(qB_st, y)  # fixes Bob's rotation for his qubit

RYGATE = np.kron(RY(theta), RY(phi))
# print(RYGATE)

# second = np.tensordot(RYGATE, first, axes=[1, 0])
second = np.matmul(first, RYGATE)
print("second =", second)
M01 = np.kron(M0, M1)
P = np.matmul(M01, second)
print(P)
