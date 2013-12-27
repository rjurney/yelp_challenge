from scipy import stats
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit
from math import log
# Build X/Y arrays from file 1
f = open('/Users/rjurney/Documents/yelp_zoom.csv')
lines = f.readlines()
x = []
y = []
for line in lines:
    line = line.replace("\n", "")
    vals = line.split(",")
    x.append(float(vals[0]))
    y.append(float(vals[1]))
x = np.array(x)
y = np.array(y)

plt.plot(x, y, 'ro',label="Original Data")
np.corrcoef(x,y) #-0.59

def func(x, a, b, c, d):
    y = a*x**3 + b*x**2 + c*x + d
    return y

def func2(x, a, b):
    y = -np.log(x) + b
    return y

popt, pcov = curve_fit(func, x, y)
print "a = %s , b = %s, c = %s, d=%s" % (popt[0], popt[1], popt[2], popt[3])

# Trying to plot without using linspace will result in a chaotic, pissy plot that will confuse you.
# numpy.linspace simply creates a series of evenly spaced X values to plot a continiuous function.
test_x = np.linspace(0,14,50)
plt.plot(test_x, func(test_x, *popt), label="Fitted Curve")
