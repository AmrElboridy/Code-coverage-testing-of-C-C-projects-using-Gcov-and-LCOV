	.file	"cond.c"
	.text
	.globl	conditionalAdd
	.def	conditionalAdd;	.scl	2;	.type	32;	.endef
	.seh_proc	conditionalAdd
conditionalAdd:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$16, %rsp
	.seh_stackalloc	16
	.seh_endprologue
	movl	%ecx, 16(%rbp)
	movl	%edx, 24(%rbp)
	movq	__gcov0.conditionalAdd(%rip), %rax
	addq	$1, %rax
	movq	%rax, __gcov0.conditionalAdd(%rip)
	movl	$0, -4(%rbp)
	cmpl	$10, 16(%rbp)
	jbe	.L2
	movq	8+__gcov0.conditionalAdd(%rip), %rax
	addq	$1, %rax
	movq	%rax, 8+__gcov0.conditionalAdd(%rip)
	cmpl	$19, 16(%rbp)
	ja	.L2
	movq	16+__gcov0.conditionalAdd(%rip), %rax
	addq	$1, %rax
	movq	%rax, 16+__gcov0.conditionalAdd(%rip)
	movl	24(%rbp), %eax
	leal	(%rax,%rax), %edx
	movl	16(%rbp), %eax
	addl	%edx, %eax
	movl	%eax, -4(%rbp)
	jmp	.L3
.L2:
	movl	24(%rbp), %eax
	movl	%eax, -4(%rbp)
.L3:
	movl	-4(%rbp), %eax
	addq	$16, %rsp
	popq	%rbp
	ret
	.seh_endproc
.lcomm __gcov0.conditionalAdd,24,16
	.data
	.align 32
__gcov_.conditionalAdd:
	.quad	.LPBX0
	.long	985948631
	.long	-1120628566
	.long	-1249818678
	.space 4
	.long	3
	.space 4
	.quad	__gcov0.conditionalAdd
	.section .rdata,"dr"
	.align 8
.LC0:
	.ascii "C:\\Projects\\EB\\Vcpu\\Tasks\\1-Video-wall_task\\File/cond.gcda\0"
	.data
	.align 32
.LPBX0:
	.long	1094202154
	.space 4
	.quad	0
	.long	-1582257795
	.space 4
	.quad	.LC0
	.quad	__gcov_merge_add
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.quad	0
	.long	1
	.space 4
	.quad	.LPBX1
	.align 8
.LPBX1:
	.quad	__gcov_.conditionalAdd
	.text
	.def	_GLOBAL__sub_I_00100_0_conditionalAdd;	.scl	3;	.type	32;	.endef
	.seh_proc	_GLOBAL__sub_I_00100_0_conditionalAdd
_GLOBAL__sub_I_00100_0_conditionalAdd:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	leaq	.LPBX0(%rip), %rcx
	call	__gcov_init
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.ctors.65435,"w"
	.align 8
	.quad	_GLOBAL__sub_I_00100_0_conditionalAdd
	.text
	.def	_GLOBAL__sub_D_00100_1_conditionalAdd;	.scl	3;	.type	32;	.endef
	.seh_proc	_GLOBAL__sub_D_00100_1_conditionalAdd
_GLOBAL__sub_D_00100_1_conditionalAdd:
	pushq	%rbp
	.seh_pushreg	%rbp
	movq	%rsp, %rbp
	.seh_setframe	%rbp, 0
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	call	__gcov_exit
	nop
	addq	$32, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.section	.dtors.65435,"w"
	.align 8
	.quad	_GLOBAL__sub_D_00100_1_conditionalAdd
	.ident	"GCC: (x86_64-posix-seh, Built by strawberryperl.com project) 8.3.0"
	.def	__gcov_merge_add;	.scl	2;	.type	32;	.endef
	.def	__gcov_init;	.scl	2;	.type	32;	.endef
	.def	__gcov_exit;	.scl	2;	.type	32;	.endef
