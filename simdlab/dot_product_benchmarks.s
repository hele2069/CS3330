	.file	"dot_product_benchmarks.c"
	.text
	.globl	dot_product_C
	.type	dot_product_C, @function
dot_product_C:
.LFB4741:
	.cfi_startproc
	testq	%rdi, %rdi
	jle	.L4
	movl	$0, %ecx
	movl	$0, %eax
.L3:
	movslq	%ecx, %r9
	movzwl	(%rsi,%r9,2), %r8d
	movzwl	(%rdx,%r9,2), %r9d
	imull	%r9d, %r8d
	addl	%r8d, %eax
	addl	$1, %ecx
	movslq	%ecx, %r8
	cmpq	%rdi, %r8
	jl	.L3
	ret
.L4:
	movl	$0, %eax
	ret
	.cfi_endproc
.LFE4741:
	.size	dot_product_C, .-dot_product_C
	.globl	functions
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"C (local)"
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC1:
	.string	"C (compiled with GCC7.2 -O3 -mavx2)"
	.data
	.align 32
	.type	functions, @object
	.size	functions, 48
functions:
	.quad	dot_product_C
	.quad	.LC0
	.quad	dot_product_gcc7_O3
	.quad	.LC1
	.quad	0
	.quad	0
	.ident	"GCC: (GNU) 7.1.0"
	.section	.note.GNU-stack,"",@progbits
