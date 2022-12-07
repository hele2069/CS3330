#include <stdio.h>
#include <stdlib.h>
#include "defs.h"
#include <immintrin.h>

/* 
 * Please fill in the following team struct 
 */
who_t who = {
    "RH",           /* Scoreboard name */

    "Yiwei He",      /* First member full name */
    "yh9vhg@virginia.edu",     /* First member email address */
};

/*** UTILITY FUNCTIONS ***/

/* You are free to use these utility functions, or write your own versions
 * of them. */

/* A struct used to compute averaged pixel value */
typedef struct {
    unsigned short red;
    unsigned short green;
    unsigned short blue;
    unsigned short alpha;
    unsigned short num;
} pixel_sum;

/* Compute min and max of two integers, respectively */
static int min(int a, int b) { return (a < b ? a : b); }
static int max(int a, int b) { return (a > b ? a : b); }

/* 
 * initialize_pixel_sum - Initializes all fields of sum to 0 
 */
static void initialize_pixel_sum(pixel_sum *sum) 
{
    sum->red = sum->green = sum->blue = sum->alpha = 0;
    sum->num = 0;
    return;
}

/* 
 * accumulate_sum - Accumulates field values of p in corresponding 
 * fields of sum 
 */
static void accumulate_sum(pixel_sum *sum, pixel p) 
{
    sum->red += (int) p.red;
    sum->green += (int) p.green;
    sum->blue += (int) p.blue;
    sum->alpha += (int) p.alpha;
    sum->num++;
    return;
}

/* 
 * assign_sum_to_pixel - Computes averaged pixel value in current_pixel 
 */
static void assign_sum_to_pixel(pixel *current_pixel, pixel_sum sum) 
{
    current_pixel->red = (unsigned short) (sum.red/sum.num);
    current_pixel->green = (unsigned short) (sum.green/sum.num);
    current_pixel->blue = (unsigned short) (sum.blue/sum.num);
    current_pixel->alpha = (unsigned short) (sum.alpha/sum.num);
    return;
}

/* 
 * avg - Returns averaged pixel value at (i,j) 
 */
static pixel avg(int dim, int i, int j, pixel *src) 
{
    pixel_sum sum;
    pixel current_pixel;

    initialize_pixel_sum(&sum);
    for(int jj=max(j-1, 0); jj <= min(j+1, dim-1); jj++) 
	for(int ii=max(i-1, 0); ii <= min(i+1, dim-1); ii++) 
	    accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    return current_pixel;
}

/******************************************************
 * Your different versions of the smooth go here
 ******************************************************/

char four_p_descr[] = "four_p: compute 4 pixels at a time";
void four_p(int dim, pixel *src, pixel *dst) {
    pixel_sum sum;
    pixel current_pixel, p;
    int i, j, ii, jj;

    // middle
    for (i = 1; i+1 < dim; i++) {
        for (j = 1; j+1 < dim; j++) {
            __m128i mp1 = _mm_loadu_si128((__m128i*) &src[RIDX(i-1, j-1, dim)]);
            __m128i mp2 = _mm_loadu_si128((__m128i*) &src[RIDX(i-1, j-0, dim)]);
            __m128i mp3 = _mm_loadu_si128((__m128i*) &src[RIDX(i-1, j+1, dim)]);
            __m128i mp4 = _mm_loadu_si128((__m128i*) &src[RIDX(i-0, j-1, dim)]);
            __m128i mp5 = _mm_loadu_si128((__m128i*) &src[RIDX(i-0, j+0, dim)]);
            __m128i mp6 = _mm_loadu_si128((__m128i*) &src[RIDX(i-0, j+1, dim)]);
            __m128i mp7 = _mm_loadu_si128((__m128i*) &src[RIDX(i+1, j-1, dim)]);
            __m128i mp8 = _mm_loadu_si128((__m128i*) &src[RIDX(i+1, j+0, dim)]);
            __m128i mp9 = _mm_loadu_si128((__m128i*) &src[RIDX(i+1, j+1, dim)]);

            __m256i p1 = _mm256_cvtepu8_epi16(mp1);
            __m256i p2 = _mm256_cvtepu8_epi16(mp2);
            __m256i p3 = _mm256_cvtepu8_epi16(mp3);
            __m256i p4 = _mm256_cvtepu8_epi16(mp4);
            __m256i p5 = _mm256_cvtepu8_epi16(mp5);
            __m256i p6 = _mm256_cvtepu8_epi16(mp6);
            __m256i p7 = _mm256_cvtepu8_epi16(mp7);
            __m256i p8 = _mm256_cvtepu8_epi16(mp8);
            __m256i p9 = _mm256_cvtepu8_epi16(mp9);

            p1 = _mm256_add_epi16(p1, p2);
            p3 = _mm256_add_epi16(p3, p4);
            p5 = _mm256_add_epi16(p5, p6);
            p7 = _mm256_add_epi16(p7, p8);
            
            __m256i sum1 = _mm256_add_epi16(p1, p3);
            __m256i sum2 = _mm256_add_epi16(p5, p7);
            __m256i px_sum = _mm256_add_epi16(_mm256_add_epi16(sum1, sum2), p9);

            __m256i val1 = _mm256_set1_epi16(7282);
            __m256i val2 = _mm256_mulhi_epi16(px_sum, val1);

            __m256i second_half = _mm256_permute2x128_si256(val2, val2, 0x34);
            __m256i packed = _mm256_packus_epi16(val2, second_half);

            __m128i result = _mm256_extracti128_si256(packed, 0);
            __m128i block = _mm_setr_epi32(-1, -1, dim-j-2, dim-j-1);
            _mm_maskstore_epi32((int*)&dst[RIDX(i, j, dim)], block, result);
        }
    }

    // sides
    int x; 
    for (j = 1; j+1 < dim; j++) {
        // top
        initialize_pixel_sum(&sum);
        for (x=0; x <= 1; x++) {
            for (jj=j-1; jj <= j+1; jj++) {
                p = src[RIDX(x,jj,dim)];
                accumulate_sum(&sum, p);
            }
        }
        sum.num = 6;
        assign_sum_to_pixel(&current_pixel, sum);
        dst[RIDX(0, j, dim)] = current_pixel;

        // bot
        initialize_pixel_sum(&sum);
        for (x=1; x <= 2; x++) {
            for (jj=j-1; jj <= j+1; jj++) {
                p = src[RIDX(dim-x,jj,dim)];
                accumulate_sum(&sum, p);
            }
        }
        sum.num = 6;
        assign_sum_to_pixel(&current_pixel, sum);
        dst[RIDX(dim-1, j, dim)] = current_pixel;
    }

    for (i = 1; i+1 < dim; i++) {
        // left 
        initialize_pixel_sum(&sum);
        for (x=0; x <= 1; x++) {
            for (ii=i-1; ii <= i+1; ii++) {
                p = src[RIDX(ii, x, dim)];
                accumulate_sum(&sum, p);
            }
        }
        sum.num = 6;
        assign_sum_to_pixel(&current_pixel, sum);
        dst[RIDX(i, 0, dim)] = current_pixel;

        // right
        initialize_pixel_sum(&sum);
        for (x=1; x <= 2; x++) {
            for(ii=i-1; ii <= i+1; ii++) {
                p = src[RIDX(ii, dim-x, dim)];
                accumulate_sum(&sum, p);
            }
        }
        sum.num = 6;
        assign_sum_to_pixel(&current_pixel, sum);
        dst[RIDX(i, dim-1, dim)] = current_pixel;
    }

    // top left
    initialize_pixel_sum(&sum);
    int y; 
    for (x = 0; x <= 1; x++) {
        for (y = 0; y <=1; y++) {
            p = src[RIDX(x, y, dim)];
            accumulate_sum(&sum, p);
        }
    }
    sum.num = 4;
    assign_sum_to_pixel(&current_pixel, sum);
    dst[RIDX(0, 0, dim)] = current_pixel;

    // top right
    initialize_pixel_sum(&sum);
    for (x = 0; x <= 1; x++) {
        for (y = 1; y <=2; y++) {
            p = src[RIDX(x, dim-y, dim)];
            accumulate_sum(&sum, p);
        }
    }
    sum.num = 4;
    assign_sum_to_pixel(&current_pixel, sum);
    dst[RIDX(0, dim-1, dim)] = current_pixel;

    // bottom left
    initialize_pixel_sum(&sum);
    for (x = 1; x <= 2; x++) {
        for (y = 0; y <=1; y++) {
            p = src[RIDX(dim-x, y, dim)];
            accumulate_sum(&sum, p);
        }
    }
    sum.num = 4;
    assign_sum_to_pixel(&current_pixel, sum);
    dst[RIDX(dim-1, 0, dim)] = current_pixel;

    // bottom right
    initialize_pixel_sum(&sum);
    for (x = 1; x <= 2; x++) {
        for (y = 1; y <=2; y++) {
            p = src[RIDX(dim-x, dim-y, dim)];
            accumulate_sum(&sum, p);
        }
    }
    sum.num = 4;
    assign_sum_to_pixel(&current_pixel, sum);
    dst[RIDX(dim-1, dim-1, dim)] = current_pixel;
}

/* 
 * naive_smooth - The naive baseline version of smooth
 */
char naive_smooth_descr[] = "naive_smooth: Naive baseline implementation";
void naive_smooth(int dim, pixel *src, pixel *dst) 
{
    for (int i = 0; i < dim; i++)
	for (int j = 0; j < dim; j++)
            dst[RIDX(i,j, dim)] = avg(dim, i, j, src);
}
/* 
 * smooth - Your current working version of smooth
 *          Our supplied version simply calls naive_smooth
 */
char another_smooth_descr[] = "another_smooth: Another version of smooth";
void another_smooth(int dim, pixel *src, pixel *dst) 
{
    naive_smooth(dim, src, dst);
}

/*********************************************************************
 * register_smooth_functions - Register all of your different versions
 *     of the smooth function by calling the add_smooth_function() for
 *     each test function. When you run the benchmark program, it will
 *     test and report the performance of each registered test
 *     function.  
 *********************************************************************/

void register_smooth_functions() {
    add_smooth_function(&naive_smooth, naive_smooth_descr);
    add_smooth_function(&another_smooth, another_smooth_descr);
    add_smooth_function(&four_p, four_p_descr);
}
