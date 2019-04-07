import numpy as np
import cmath
import numpy as np
import scipy as sp
import scipy.linalg

# Zero = np.array([[1.0],
#                  [0.0]])
# One = np.array([[0.0],
#                 [1.0]])
#
# NormalizeState = lambda state: state / sp.linalg.norm(state)
#
# Plus = NormalizeState(Zero + One)
#
# Hadamard = 1./np.sqrt(2) * np.array([[1, 1],
#                                      [1, -1]])
#
# NewState = np.dot(Hadamard, Zero)
# print(NewState)

# a = np.array([1+2j,3+4j, 5+6j])
# c = np.array([0+1j,1+0j, 2+3j])
# b = np.vdot(a, a)
# d = np.vdot(c, c)
# print(cmath.sqrt(b))
# print(cmath.sqrt(d))
# print(cmath.sqrt(1+2j))
# print(np.vdot(a, c))
# print(a)
# print(a + c)
# print(a - c)
# print(np.vdot(a, c))
# print(a*2)
# print(c*2)
# # print(cmath.sqrt(np.vdot(a, c)))

v = np.array([2+3j, 0-2j, 5+0j, 0+1j])
w = np.array([0-1j, -1+0j, 3-1j, -1-1j])

print(np.vdot(w, v))

# print(complex(0, -1) * complex(1, 0))
