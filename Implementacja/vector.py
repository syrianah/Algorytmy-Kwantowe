import numpy as np
from complex import Complex
import cmath
import math
from qubit import Qubit

class Vector:

    def __init__(self, values = []):
        self.values = values

    def __add__(self, other):
    	temp = []
    	for j in range(len(self.values)):
    		temp.append(self.values[j] + other.values[j])
    	return Vector(temp)

    def __sub__(self, other):
    	temp = []
    	for j in range(len(self.values)):
    		temp.append(self.values[j] - other.values[j])
    	return Vector(temp)

    def skalar(self, n):
        temp = []
        for j in range(len(self.values)):
            temp.append(self.values[j] * n)
        return Vector(temp)

    def __mul__(self, other):
        temp = Complex(0, 0)
        for j in range(len(self.values)):
             temp = temp + (self.values[j] * other.values[j].sprz())
        return temp

    def norma(self):
        temp = Complex(0, 0)
        for j in range(len(self.values)):
             temp = temp + (self.values[j] * self.values[j].sprz())
        return temp**0.5

    def __repr__(self):
        return str(self.values)

def mul(M, V):
    for i in range(len(V.values)):
        alfa = M[0, 0] * V.values[i] + M[1, 0] * V.values[i+1]
        beta = M[0, 1] * V.values[i] + M[1, 1] * V.values[i+1]
    return Qubit(alfa, beta)


a = Complex(1, 2)
b = Complex(3, 4)
c = Complex(5, 6)
d = Complex(0, 1)
e = Complex(1, 0)
f = Complex(2, 3)
al = 1/math.sqrt(2)
vector1 = Vector([a, b, c])
vector2 = Vector([d, e, f])

H = np.array([[1, 1],[1, -1]])
V = Vector([al, al])
wynik = mul(H, V)

# print(vector1)
# print(vector1 + vector2)
# print(vector1 - vector2)
# print(vector1.skalar(2))
# print(vector2.skalar(3))
# print(vector1 * vector2)
# print(vector1.norma())
# print(vector2.norma())
