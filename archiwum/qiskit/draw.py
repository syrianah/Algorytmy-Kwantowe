from qiskit import QuantumCircuit, ClassicalRegister, QuantumRegister
from qiskit.tools.visualization import circuit_drawer
from matplotlib import pyplot as plt

# Build a quantum circuit

n = 3  # number of qubits
q = QuantumRegister(n)

circuit = QuantumCircuit(q)

circuit.ccx(q[0], q[1], q[2])

print(circuit)

circuit.draw(output='mpl')

circuit.draw(output='mpl').savefig('foo.png')

# # Print the latex source for the visualization
# print(circuit.draw(output='latex_source'))

