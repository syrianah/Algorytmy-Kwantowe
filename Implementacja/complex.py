import math
twopi = math.pi * 2
halfpi = math.pi * 0.5

def Re(object):
    return object.real


def Im(object):
    return object.imag

def PolarToComplex(r = 0, phi = 0):
    phi = math.radians(phi)
    return Complex(math.cos(phi)*r, math.sin(phi)*r)

class Complex:
    def __init__(self, real, imag=0.0):
        self.real = real
        self.imag = imag

    def __add__(self, other):
        return Complex(self.real + other.real,
                       self.imag + other.imag)

    def __sub__(self, other):
        return Complex(self.real - other.real,
                       self.imag - other.imag)

    def __mul__(self, other):
        return Complex(self.real*other.real - self.imag*other.imag,
                       self.imag*other.real + self.real*other.imag)

    def __truediv__(self, other):
        d = float(other.real*other.real + other.imag*other.imag)
        if not d:
             raise ZeroDivisionError('Complex division')
        else:
            return Complex((self.real*other.real + self.imag*other.imag) / d,
                       (self.imag*other.real - self.real*other.imag) /d)

    def __abs__(self):
        return math.hypot(self.real, self.imag)

    def sprz(self):
        return Complex(self.real, -self.imag)

    def __repr__(self):
        return "{} {}".format(self.real, self.imag)

    def enum(self):
        return Complex(math.exp(self.real)*math.cos(self.imag),
                        math.exp(self.real)*math.sin(self.imag))

    def sqrt(self):
        r = abs(self)
        phi = math.degrees(math.cos(self.real/abs(self)))/2
        return Complex(math.cos(phi) * math.sqrt(r), math.sin(phi) * math.sqrt(r))

    def ComplexToPolar(self):
        return "{} {}".format(abs(self), self.angle())

    def angle(self, fullcircle = twopi):
        return (fullcircle/twopi) * ((halfpi - math.atan2(self.real, self.imag)) % twopi)

    def __pow__(self, n):
        r = pow(abs(self), n)
        phi = n*self.angle()
        return Complex(math.cos(phi)*r, math.sin(phi)*r)


# num1 = Complex(1, 2)
# num2 = Complex(2, 2)
# # print(num1.number())
# # print(num2.number())
# print(num1 + num2)
# print(num1 - num2)
# print(num1 * num2)
# print(num1 / num2)
#
# num3 = PolarToComplex(1, 60)
# print(num3)
# print(Re(num2))
# print(abs(num2))
# print(num1.sprz())
# print(num1.enum())
# print(num1**0.5)
# print(num1.ComplexToPolar())
# print(num1.sqrt())
# epi4 = PolarToComplex(1, 45)
# print(epi4)
