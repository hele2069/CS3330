
def addOK(x, y):
    sum = x + y
    return (((x ^ y) | ~(sum ^ x)) >> 31) & 1

