import sys
from ulab import numpy

a = numpy.arange(6)
print(a)
b = a.reshape((2, 3))
print(b)
print(numpy.sqrt(b))
