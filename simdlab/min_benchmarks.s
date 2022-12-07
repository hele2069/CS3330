	.file	"min_benchmarks.c"
	.text
	.globl	min_C
	.type	min_C, @function
min_C:
.LFB4741:
	.cfi_startproc
	testq	%rdi, %rdi
	jle	.L4
	movl	$0, %edx
	movl	$32767, %eax
.L3:
	movslq	%edx, %rcx
	movzwl	(%rsi,%rcx,2), %ecx
	cmpw	%cx, %ax
	cmovg	%ecx, %eax
	addl	$1, %edx
	movslq	%edx, %rcx
	cmpq	%rdi, %rcx
	jl	.L3
	ret
.L4:
	movl	$32767, %eax
	ret
	.cfi_endproc
.LFE4741:
	.size	min_C, .-min_C
	.globl	functions
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"C (local)"
	.data
	.align 32
	.type	functions, @object
	.size	functions, 32
functions:
	.quad	min_C
	.quad	.LC0
	.quad	0
	.quad	0
	.ident	"GCC: (GNU) 7.1.0"
	.section	.note.GNU-stack,"",@progbits
