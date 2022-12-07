#include <stdlib.h>
#include <limits.h>  /* for USHRT_MAX */

#include <immintrin.h>

#include "min.h"
/* reference implementation in C */
short min_C(long size, short * a) {
    short result = SHRT_MAX;
    for (int i = 0; i < size; ++i) {
        if (a[i] < result)
            result = a[i];
    }
    return result;
}


/* This is the list of functions to test */
function_info functions[] = {
    {min_C, "C (local)"},
    // add entries here!
    {NULL, NULL},
};
