
def fiveeighths(x):
    eights = x >> 3
    rem = x & 7
    return eights + (eights << 2) + (rem + (rem << 2) + (x >> 31 & 7) >> 3)

