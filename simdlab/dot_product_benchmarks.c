#include <stdlib.h>

#include <immintrin.h>

#include "dot_product.h"
/* reference implementation in C */
unsigned int dot_product_C(long size, unsigned short * a, unsigned short *b) {
    unsigned int sum = 0;
    for (int i = 0; i < size; ++i) {
        sum += a[i] * b[i];
    }
    return sum;
}

// add prototypes here!
extern unsigned int dot_product_gcc7_O3(long size, unsigned short * a, unsigned short *b);

/* This is the list of functions to test */
function_info functions[] = {
    {dot_product_C, "C (local)"},
    {dot_product_gcc7_O3, "C (compiled with GCC7.2 -O3 -mavx2)"},
    // add entries here!
    {NULL, NULL},
};
