#include <stdio.h>

/*
This template code works by accessing elements of an array in a particular order in a loop.
Since this is the only memory location accessed by the loop (assuming i, j are stored in registers)
and the loop makes for a vast majority of the data memory accesses, these accesses will
determine the cache miss rate.

By default, the template will provide accesses element
0, 4, 8, 12, 16, 20, 24, 28, ..., 1048564, 0, 4, 8, 12, ...
until it has performed 64 million accesses.

(The accesses happen in the second loop below, which will usually account for a majority
of the data cache accesses. The first loop below sets up the array to make second loop
work well.)

If you run this with a 32KB, 64B block size 2-way set associative data cache (with an LRU policy),
this results in about a 75% hit rate:

*  when index 0 is accessed, the whole cache block containing indices 0-15 inclusive (64 bytes)
   is loaded into the cache (if it wasn't already); this means that indices 4, 8, 12 are hits.

   Similarly, indices 20, 24, and 28 will be hits; and 36, 40, 44; and so on.

*  when index 0 is accessed the second time, it will be a cache miss even though it was loaded into
   the cache for the first access. This is because in between the first and second access,
   the cache needs to load index 8192 and index 16384 and index 24576, etc. --- all of which will
   map to the same set of the cache. Since each set can only store two values, and the block containing
   index 0 will be less recently used than many other values, it will be evicted.

   Similarly, when index 16 is accessed the second time, it will also be a cache miss.

Combined, these two observations mean that every fourth access will be a miss and all other accesses
will be hits. (I neglected to analyze what happens for the first access to index 0, index 16, etc. or
what happens in the loop that initializes the array ---
since there are so many more accesses to these indices after initialization, we can neglect them for the
purposes of our analysis. As long as we set the number of total accesses high enough,
the "warmup" accesses will have a small enough effect that we'll still be able to achieve hit
rates in the target ranges.)

You can edit this code:
*  to adjust the maximum index used by changing MAX;
*  to adjust the interval between indexes by changing SKIP;
*  to adjust the number of accesses by changing ITERS;

The code works by setting up each element array to contain the index of the next one
to access (so, with index 0 will contain 4, 4 will contain 8, 1048564 will contain 0, etc.),
and then accessing the array in a loop to find the next array element to access.
This prevents some clever techniques where the compiler or processor might skip some
array accesses or perform multiple array accesses in parallel.
*/

/* if GCC is used to compile this, disable optimizations (if not already disabled)
   that are likely to make the compiler generate a non-intutive access pattern */
#pragma GCC optimize (2, "no-tree-vectorize")

/* array of about 1M ints, configured to be placed at an address that's a multiple of 128 */
int global_array[1048568] __attribute__((aligned(128)));

/*
This tells GCC or Clang to assume that the array is being modified,
so it doesn't try optimize based on assuming it knows what values it contains.

(It works by saying "here's some inline assembly (which happens to be blank),
and, by the way, compiler, it might modify values in memory.)
*/
void prevent_optimizations_based_on_knowing_array_values() {
    __asm__ volatile ("":::"memory");
}

int main() {
    const int MAX = 1048568;
    const int SKIP = 4;
    const int ITERS = 64000000;

/* these two lines tell Clang (if used to compile this) not to try to 
   perform optimizations on this loop that are likely to make the access
   pattern not very intutive */
#pragma clang loop vectorize(disable)
#pragma clang loop interleave(disable)

    /* This loop sets up global_array[i] for the next loop.
     * Most of the accesses to the array are likely to happen in the second loop. */
    for (int i = 0; i < MAX; ++i) {
        global_array[i] = (i+SKIP) % (MAX);
    }
    prevent_optimizations_based_on_knowing_array_values();
    int j = 0;

    
#pragma clang loop vectorize(disable)
#pragma clang loop interleave(disable)

    /* This loop performs the actual array accesses described above.
     * This is where most of the data cache accesses are likely to occur.
     */
    for (int i = 0; i < ITERS; ++i) {
        j = global_array[j];
    }
    /* print out j to ensure that the compiler doesn't optimize the array accesses above away */
    printf("%d\n", j);
}

