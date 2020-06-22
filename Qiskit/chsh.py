import numpy as np
import random as rand

# importing Qiskit
from qiskit import BasicAer
from qiskit import QuantumCircuit, ClassicalRegister, QuantumRegister, execute


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


# Alice's strategy
qA_st = int(input(
    'select the quantum strategy for Alice, input 1,2 or 3 to pick one of the strategies listed above: '))

# Bob's strategy
qB_st = int(input(
    'select the quantum strategy for Bob, input 1,2 or 3 to pick one of the strategies listed above: '))

# set parameters of the quantum run of the game
shots = 1  # set how many times the circuit is run, accumulating statistics about the measurement outcomes
# set the machine where the quantum circuit is to be run
backend = BasicAer.get_backend('qasm_simulator')

# fixes the numbers of games to be played
N = 100

# initializes counters used to keep track of the numbers of games won and played by Alice an Bob
cont_win = 0  # counts games won
cont_tot = 0  # counts games played

# play N games
for i in range(N):

    # creates registers for qubits and bits
    # creates a quantum register, it specifies the qubits which are going to be used for the program
    q = QuantumRegister(2, name='q')
    # creates a classical register, the results of the measurement of the qubits are stored here
    c = ClassicalRegister(2, name='c')

    # creates quantum circuit, to write a quantum algorithm we will add gates to the circuit
    game = QuantumCircuit(q, c, name='game')

    # These gates prepare the entangled Bell pair to be shared by Alice and Bob as part of their quantum strategy
    # Alice will have qubit 0 and Bob will have qubit 1
    game.h(q[0])  # Hadamard gate on qubit 0
    game.cx(q[0], q[1])  # CNOT gate on qubit 1 controlled by qubit 0

    # generates two random input from the refree, x and y, to be given to Alice and Bob
    random_num1 = rand.random()  # first random number
    random_num2 = rand.random()  # second random number

    if(random_num1 >= 1/2):  # converts the first random number to 0 or 1
        x = 0
    else:
        x = 1

    if(random_num2 >= 1/2):  # converts the second random number to 0 or 1
        y = 0
    else:
        y = 1

    # The main part of Alice and Bob quantum strategy is to fix different rotation angles for their qubit according to the input x,y
    theta = qAlice_output(qA_st, x)  # fixes Alice's rotation for her qubit
    phi = qBob_output(qB_st, y)  # fixes Bob's rotation for his qubit

    # The following gates rotate Alice's qubit and Bob's qubit
    game.ry(theta, q[0])  # rotates Alice's qubit of an angle theta
    game.ry(phi, q[1])  # rotates Bob's qubit of an angle phi

    # These gates are used to measure  the value of the qubits
    # measure Alice's qubit and stores the result in a classical bit
    game.measure(q[0], c[0])
    # measure Bob's qubit and stores the result in a classical bit
    game.measure(q[1], c[1])

    # executes circuit and store the output of the measurements
    result = execute(game, backend=backend, shots=shots).result()

    # extract the outcomes and their statistics from the result of the execution
    data = result.get_counts('game')

    # reads the result of the measurements of the quantum system
    for outcomes in data.keys():
        out = outcomes

    # converts the result of the measurements contained in the classical register as string '00', '01', '10', '11',
    # which are the answers of Alice(a) and Bob (b), from a 'string' type  to 'integer' type
    if(out == '00'):
        a = 0
        b = 0
    if(out == '01'):
        a = 1
        b = 0
    if(out == '10'):
        a = 0
        b = 1
    if(out == '11'):
        a = 1
        b = 1

    # check if the condition for winning the game is met
    if(x*y == a ^ b):
        cont_win += 1  # increase thes won games' counter if the condition to win the game is met

    cont_tot += 1  # increases the played games' counter

qProb_win = cont_win/cont_tot

print('Alice and Bob won the game with probability: ', qProb_win*100, '%')

if qProb_win > qProb_win:
    print("The classical strategy gave Alice and Bob higher chances of winning")
else:
    print("The quantum strategy gave Alice and Bob higher chances of winning")
