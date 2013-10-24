
hello:     file format elf64-x86-64

Disassembly of section .init:

0000000000400370 <_init>:
  400370:	48 83 ec 08          	sub    $0x8,%rsp
  400374:	e8 73 00 00 00       	callq  4003ec <call_gmon_start>
  400379:	e8 f2 00 00 00       	callq  400470 <frame_dummy>
  40037e:	e8 cd 01 00 00       	callq  400550 <__do_global_ctors_aux>
  400383:	48 83 c4 08          	add    $0x8,%rsp
  400387:	c3                   	retq   
Disassembly of section .plt:

0000000000400388 <puts@plt-0x10>:
  400388:	ff 35 6a 04 20 00    	pushq  2098282(%rip)        # 6007f8 <_GLOBAL_OFFSET_TABLE_+0x8>
  40038e:	ff 25 6c 04 20 00    	jmpq   *2098284(%rip)        # 600800 <_GLOBAL_OFFSET_TABLE_+0x10>
  400394:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000400398 <puts@plt>:
  400398:	ff 25 6a 04 20 00    	jmpq   *2098282(%rip)        # 600808 <_GLOBAL_OFFSET_TABLE_+0x18>
  40039e:	68 00 00 00 00       	pushq  $0x0
  4003a3:	e9 e0 ff ff ff       	jmpq   400388 <_init+0x18>

00000000004003a8 <__libc_start_main@plt>:
  4003a8:	ff 25 62 04 20 00    	jmpq   *2098274(%rip)        # 600810 <_GLOBAL_OFFSET_TABLE_+0x20>
  4003ae:	68 01 00 00 00       	pushq  $0x1
  4003b3:	e9 d0 ff ff ff       	jmpq   400388 <_init+0x18>
Disassembly of section .text:

00000000004003c0 <_start>:
  4003c0:	31 ed                	xor    %ebp,%ebp
  4003c2:	49 89 d1             	mov    %rdx,%r9
  4003c5:	5e                   	pop    %rsi
  4003c6:	48 89 e2             	mov    %rsp,%rdx
  4003c9:	48 83 e4 f0          	and    $0xfffffffffffffff0,%rsp
  4003cd:	50                   	push   %rax
  4003ce:	54                   	push   %rsp
  4003cf:	49 c7 c0 b0 04 40 00 	mov    $0x4004b0,%r8
  4003d6:	48 c7 c1 c0 04 40 00 	mov    $0x4004c0,%rcx
  4003dd:	48 c7 c7 98 04 40 00 	mov    $0x400498,%rdi
  4003e4:	e8 bf ff ff ff       	callq  4003a8 <__libc_start_main@plt>
  4003e9:	f4                   	hlt    
  4003ea:	90                   	nop    
  4003eb:	90                   	nop    

00000000004003ec <call_gmon_start>:
  4003ec:	48 83 ec 08          	sub    $0x8,%rsp
  4003f0:	48 8b 05 f1 03 20 00 	mov    2098161(%rip),%rax        # 6007e8 <_DYNAMIC+0x190>
  4003f7:	48 85 c0             	test   %rax,%rax
  4003fa:	74 02                	je     4003fe <call_gmon_start+0x12>
  4003fc:	ff d0                	callq  *%rax
  4003fe:	48 83 c4 08          	add    $0x8,%rsp
  400402:	c3                   	retq   
  400403:	90                   	nop    
  400404:	90                   	nop    
  400405:	90                   	nop    
  400406:	90                   	nop    
  400407:	90                   	nop    
  400408:	90                   	nop    
  400409:	90                   	nop    
  40040a:	90                   	nop    
  40040b:	90                   	nop    
  40040c:	90                   	nop    
  40040d:	90                   	nop    
  40040e:	90                   	nop    
  40040f:	90                   	nop    

0000000000400410 <__do_global_dtors_aux>:
  400410:	55                   	push   %rbp
  400411:	48 89 e5             	mov    %rsp,%rbp
  400414:	53                   	push   %rbx
  400415:	48 83 ec 08          	sub    $0x8,%rsp
  400419:	80 3d 08 04 20 00 00 	cmpb   $0x0,2098184(%rip)        # 600828 <completed.6145>
  400420:	75 44                	jne    400466 <__do_global_dtors_aux+0x56>
  400422:	b8 48 06 60 00       	mov    $0x600648,%eax
  400427:	48 2d 40 06 60 00    	sub    $0x600640,%rax
  40042d:	48 c1 f8 03          	sar    $0x3,%rax
  400431:	48 8d 58 ff          	lea    0xffffffffffffffff(%rax),%rbx
  400435:	48 8b 05 e4 03 20 00 	mov    2098148(%rip),%rax        # 600820 <dtor_idx.6147>
  40043c:	48 39 c3             	cmp    %rax,%rbx
  40043f:	76 1e                	jbe    40045f <__do_global_dtors_aux+0x4f>
  400441:	48 83 c0 01          	add    $0x1,%rax
  400445:	48 89 05 d4 03 20 00 	mov    %rax,2098132(%rip)        # 600820 <dtor_idx.6147>
  40044c:	ff 14 c5 40 06 60 00 	callq  *0x600640(,%rax,8)
  400453:	48 8b 05 c6 03 20 00 	mov    2098118(%rip),%rax        # 600820 <dtor_idx.6147>
  40045a:	48 39 c3             	cmp    %rax,%rbx
  40045d:	77 e2                	ja     400441 <__do_global_dtors_aux+0x31>
  40045f:	c6 05 c2 03 20 00 01 	movb   $0x1,2098114(%rip)        # 600828 <completed.6145>
  400466:	48 83 c4 08          	add    $0x8,%rsp
  40046a:	5b                   	pop    %rbx
  40046b:	c9                   	leaveq 
  40046c:	c3                   	retq   
  40046d:	0f 1f 00             	nopl   (%rax)

0000000000400470 <frame_dummy>:
  400470:	55                   	push   %rbp
  400471:	48 83 3d d7 01 20 00 	cmpq   $0x0,2097623(%rip)        # 600650 <__JCR_END__>
  400478:	00 
  400479:	48 89 e5             	mov    %rsp,%rbp
  40047c:	74 16                	je     400494 <frame_dummy+0x24>
  40047e:	b8 00 00 00 00       	mov    $0x0,%eax
  400483:	48 85 c0             	test   %rax,%rax
  400486:	74 0c                	je     400494 <frame_dummy+0x24>
  400488:	bf 50 06 60 00       	mov    $0x600650,%edi
  40048d:	49 89 c3             	mov    %rax,%r11
  400490:	c9                   	leaveq 
  400491:	41 ff e3             	jmpq   *%r11
  400494:	c9                   	leaveq 
  400495:	c3                   	retq   
  400496:	90                   	nop    
  400497:	90                   	nop    

0000000000400498 <main>:
  400498:	55                   	push   %rbp
  400499:	48 89 e5             	mov    %rsp,%rbp
  40049c:	bf a8 05 40 00       	mov    $0x4005a8,%edi
  4004a1:	e8 f2 fe ff ff       	callq  400398 <puts@plt>
  4004a6:	b8 00 00 00 00       	mov    $0x0,%eax
  4004ab:	c9                   	leaveq 
  4004ac:	c3                   	retq   
  4004ad:	90                   	nop    
  4004ae:	90                   	nop    
  4004af:	90                   	nop    

00000000004004b0 <__libc_csu_fini>:
  4004b0:	f3 c3                	repz retq 
  4004b2:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
  4004b9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000004004c0 <__libc_csu_init>:
  4004c0:	4c 89 64 24 e0       	mov    %r12,0xffffffffffffffe0(%rsp)
  4004c5:	4c 89 6c 24 e8       	mov    %r13,0xffffffffffffffe8(%rsp)
  4004ca:	4c 8d 25 5b 01 20 00 	lea    2097499(%rip),%r12        # 60062c <__fini_array_end>
  4004d1:	4c 89 74 24 f0       	mov    %r14,0xfffffffffffffff0(%rsp)
  4004d6:	4c 89 7c 24 f8       	mov    %r15,0xfffffffffffffff8(%rsp)
  4004db:	49 89 f6             	mov    %rsi,%r14
  4004de:	48 89 5c 24 d0       	mov    %rbx,0xffffffffffffffd0(%rsp)
  4004e3:	48 89 6c 24 d8       	mov    %rbp,0xffffffffffffffd8(%rsp)
  4004e8:	48 83 ec 38          	sub    $0x38,%rsp
  4004ec:	41 89 ff             	mov    %edi,%r15d
  4004ef:	49 89 d5             	mov    %rdx,%r13
  4004f2:	e8 79 fe ff ff       	callq  400370 <_init>
  4004f7:	48 8d 05 2e 01 20 00 	lea    2097454(%rip),%rax        # 60062c <__fini_array_end>
  4004fe:	49 29 c4             	sub    %rax,%r12
  400501:	49 c1 fc 03          	sar    $0x3,%r12
  400505:	4d 85 e4             	test   %r12,%r12
  400508:	74 1e                	je     400528 <__libc_csu_init+0x68>
  40050a:	31 ed                	xor    %ebp,%ebp
  40050c:	48 89 c3             	mov    %rax,%rbx
  40050f:	90                   	nop    
  400510:	48 83 c5 01          	add    $0x1,%rbp
  400514:	4c 89 ea             	mov    %r13,%rdx
  400517:	4c 89 f6             	mov    %r14,%rsi
  40051a:	44 89 ff             	mov    %r15d,%edi
  40051d:	ff 13                	callq  *(%rbx)
  40051f:	48 83 c3 08          	add    $0x8,%rbx
  400523:	49 39 ec             	cmp    %rbp,%r12
  400526:	75 e8                	jne    400510 <__libc_csu_init+0x50>
  400528:	48 8b 5c 24 08       	mov    0x8(%rsp),%rbx
  40052d:	48 8b 6c 24 10       	mov    0x10(%rsp),%rbp
  400532:	4c 8b 64 24 18       	mov    0x18(%rsp),%r12
  400537:	4c 8b 6c 24 20       	mov    0x20(%rsp),%r13
  40053c:	4c 8b 74 24 28       	mov    0x28(%rsp),%r14
  400541:	4c 8b 7c 24 30       	mov    0x30(%rsp),%r15
  400546:	48 83 c4 38          	add    $0x38,%rsp
  40054a:	c3                   	retq   
  40054b:	90                   	nop    
  40054c:	90                   	nop    
  40054d:	90                   	nop    
  40054e:	90                   	nop    
  40054f:	90                   	nop    

0000000000400550 <__do_global_ctors_aux>:
  400550:	55                   	push   %rbp
  400551:	48 89 e5             	mov    %rsp,%rbp
  400554:	53                   	push   %rbx
  400555:	bb 30 06 60 00       	mov    $0x600630,%ebx
  40055a:	48 83 ec 08          	sub    $0x8,%rsp
  40055e:	48 8b 05 cb 00 20 00 	mov    2097355(%rip),%rax        # 600630 <__CTOR_LIST__>
  400565:	48 83 f8 ff          	cmp    $0xffffffffffffffff,%rax
  400569:	74 14                	je     40057f <__do_global_ctors_aux+0x2f>
  40056b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  400570:	48 83 eb 08          	sub    $0x8,%rbx
  400574:	ff d0                	callq  *%rax
  400576:	48 8b 03             	mov    (%rbx),%rax
  400579:	48 83 f8 ff          	cmp    $0xffffffffffffffff,%rax
  40057d:	75 f1                	jne    400570 <__do_global_ctors_aux+0x20>
  40057f:	48 83 c4 08          	add    $0x8,%rsp
  400583:	5b                   	pop    %rbx
  400584:	c9                   	leaveq 
  400585:	c3                   	retq   
  400586:	90                   	nop    
  400587:	90                   	nop    
Disassembly of section .fini:

0000000000400588 <_fini>:
  400588:	48 83 ec 08          	sub    $0x8,%rsp
  40058c:	e8 7f fe ff ff       	callq  400410 <__do_global_dtors_aux>
  400591:	48 83 c4 08          	add    $0x8,%rsp
  400595:	c3                   	retq   
