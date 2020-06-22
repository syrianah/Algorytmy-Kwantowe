from qubitNew import Qubit, tensordot, Hadamard, Cnot, Measure, Identity, randomQ, M0, M1, RY
# from complex import Complex
import numpy as np
import random as rand

N = 100


def MultyQubitMeasure(states):
    probability = []
    arr = ["00", "01", "10", "11"]
    for i, state in enumerate(states):
        P = np.absolute(state)**2
        probability.append((P, arr[i]))
    # print(max(probability))
    maxP = max(probability)
    return maxP[1]
    # P = rand.uniform(0, 1)
    # if P < maxP[0]:
    #     return maxP[1]
    # else:
    #     return 1


def qAlice_output(strategy, inp):
    if(strategy == 1):
        return 0

    elif(strategy == 2):
        return rand.uniform(0, 2*np.pi)

    elif(strategy == 3):
        if(inp == 0):
            return 0
        elif(inp == 1):
            return np.pi/4

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
            return np.pi/8
        elif(inp == 1):
            return -np.pi/8

    else:
        print("INVALID choice")
        return 100


# Inicjalizacja macierzy pomiaru
M0 = M0()
M1 = M1()
M00 = np.kron(M0, M0)
M01 = np.kron(M0, M1)
M10 = np.kron(M1, M0)
M11 = np.kron(M1, M1)

# Inicjalizacja Bramek
H = Hadamard()
CNOT = Cnot()
I = Identity()


# # Alice's strategy
# qA_st = int(input(
#     'select the quantum strategy for Alice, input 1,2 or 3 to pick one of the strategies listed above: '))

# # Bob's strategy
# qB_st = int(input(
#     'select the quantum strategy for Bob, input 1,2 or 3 to pick one of the strategies listed above: '))

qA_st = 3
qB_st = 3

# fixes the numbers of games to be played
# N = 100


def game(N):
    # initializes counters used to keep track of the numbers of games won and played by Alice an Bob
    cont_win = 0  # counts games won
    cont_tot = 0  # counts games played

    # play N games
    for _ in range(N):
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
        second = np.matmul(RYGATE, first)
        print("second = ", second)

        print("**********************************")

        # print("Bramki pomiaru:")
        # PM00 = np.matmul(M00, second)
        PM01 = np.matmul(M01, second)
        # PM11 = np.matmul(M11, second)
        # PM10 = np.matmul(M10, second)
        # print("PM00 = ", PM00)
        # print("PM01 = ", PM01)
        # print("PM11 = ", PM11)
        # print("PM10 = ", PM10)

        measure = MultyQubitMeasure(PM01)
        print("Pomiar = ", measure)
        a = int(measure[1])
        b = int(measure[0])
        print("kąty:", theta, phi)
        print("x, y <=> ", x, y)
        print("a, b <=> ", a, b)
        print("**********************************")

        # check if the condition for winning the game is met
        if(x*y == a ^ b):
            cont_win += 1  # increase thes won games' counter if the condition to win the game is met

        cont_tot += 1  # increases the played games' counter

    qProb_win = cont_win/cont_tot

    print('Alice and Bob won the game with probability: ', qProb_win*100, '%')


game(100)
