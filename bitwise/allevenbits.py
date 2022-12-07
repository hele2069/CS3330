
def allEvenBits(x):
    print(format(x,'b'))
    print(format(x,'b'),format(x>>16,'b'))
    x = x & x >> 16
    print(format(x,'b'))
    x = x & x >> 8
    print(format(x,'b'))
    x = x & x >> 4
    print(format(x,'b'))
    x = x & x >> 2
    print(format(x,'b'))
    print(format(x&1,'b'))
    return x&1

#print(allEvenBits(0x2B))
#print(allEvenBits(0x2A))
print(allEvenBits(0x155555555))