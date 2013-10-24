	.section	.rodata
.LC0:
	.string	"Hello"
	.text
.globl main
	.type	main, @function
main:
	pushq	%rbp
	movq	%rsp, %rbp
	movl	$.LC0, %edi
	call	puts
	movl	$0, %eax
	leave
	ret
