; =======================================
; pmtest.asm
; 编译方式: nasm pmtest.asm -o pmtest.com
; ========================================

%include "pm.inc"		;常量,宏, 以及一些说明

PageDirBase0		equ 200000h	;页目录开始地址: 2M
PageTblBase0		equ 201000h	;页表开始位置: 2M + 4K
PageDirBase1		equ	210000h ;页目录开始地址: 2M + 64K
PageTblBase1		equ 211000h	;页表开始地址: 2M + 64K + 4K

LinearAddrDemo 		equ 00401000h
ProcFoo				equ 00401000h
ProcBar				equ 00501000h
ProcPagingDemo		equ 00301000h

org 0100h
	jmp LABEL_BEGIN

[SECTION .gdt]
; GDT
; 
LABEL_GDT:			Descriptor	0,				0,	0					; 空描述符
LABEL_DESC_NORMAL:	Descriptor	0,			0ffffh,
LABEL_DESC_FLAT_C:
LABEL_DESC_FLAT_RW:
LABEL_DESC_CODE32:
LABEL_DESC_CODE16:
LABEL_DESC_DATA:
LABEL_DESC_STACK:
LABEL_DESC_VIDEO:
; GDT 结束

GdtLen			equ $ - LABEL_GDT	;
GdtPtr			dw GdtLen - 1		;

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorFlatC		equ LABEL_DESC_FLAT_C 	- LAEBL_GDT
SelectorFlatRW		equ LABEL_DESC_FLAT_RW	- LABEL_GDT
SelectorCode32		equ LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16 		equ LABEL_DESC_CODE16	- LABEL_GDT
SelectorData		equ LABEL_DESC_DATA		- LABEL_GDT
SelectorStack		equ LABEL_DESC_STACK	- LABEL_GDT
SelectorVideo		equ LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]

[SECTION .data1]
ALIGN 	32
[BITS 	32]
LABEL_DATA:
; 实模式下使用这些符号
; 字符串
_szPMMessage:
_szMemChkTitle:
_szRAMSize:
_szReturn:

;变量

DataLen 		equ $ - LABEL_DATA
; END of [SECTION .data1]

; IDT
[SECTION .idt]
ALIGN 	32
[BITS	32]
LABEL_IDT:
; 门
%rep 128
			Gate	SelectorCode32, SpuriousHandler, 0,	DA_386IGate
%endrep
.080h:		Gate	SelectorCode32,	UserIntHandler,  0, DA_386IGate

IdtLen		equ $ - LABEL_IDT
IdtPtr		dw IdtLen - 1		;
		dd	0					;基地址
; END of [SECTION .idt]

; 全局堆栈段
[SECTION .gs]
ALIGN 	32
[BITS	32]
LABEL_STACK:
	times 512 db 0

TopOfStack	equ $ - LABEL_STACK - 1

; END of [SECTION .gs]

[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0100h
	
	mov [LABEL_GO_BACK_TO_REAL + 3], ax
	mov [_wSPValueInRealMode], sp

	; 得到内存数
	mov ebx, 0
	mov di. _MemChkBuf

.loop:
	mov eax, 0E82h
	mov ecx, 20
	mov edx, 0534D4150h
	int 15h
	jc LABEL_MEM_CHK_FAIL
	add di, 20
	inc dword [_dwMCRNumber]
	cmp ebx, 0
	jne .loop
	jmp LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
	mov dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:

	; 初始化 16为代码段描述符
	mov ax, cs
	movzx eax, ax
	shl eax, 4
	add eax, LABEL_SEG_CODE16
	mov word [LABEL_DESC_CODE16 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE16 + 4], al
	mov byte [LABEL_DESC_CODE16 + 7], ah
	
	; 初始化 32 位代码描述符
	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE32
	mov word [LABEL_DESC_CODE32 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32 + 4], al
	mov byte [LABEL_DESC_CODE32 + 7], ah
		
	; 初始化数据段描述符
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_DATA
	mov word [LABEL_DESC_DATA + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_DATA + 4], al
	mov byte [LABEL_DESC_DATA + 7], ah
	
	; 初始化堆栈描述符
	xor eax, eax	
	mov ax, ds
	shl eax, 4
	add eax, LABEL_STACK
	mov word [LABEL_DESC_STACK + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_STACK + 4], al
	mov byte [LABEL_DESC_STACK + 7], ah
	
	; 为加载 GDTR 作准备
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_GDT			; eax <- gdt 基地址
	mov dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gtd 基地址
	
	; 为加载IDTR 作准备
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_IDT			;
	mov dword [IdtPtr + 2], eax	;	
	
	; 加载 GDTR
	lgdt [GdtPtr]

	; 关中断
	cli

	; 加载 IDTR
	lidt [IdtPtr]

	; 打开地址线A20
	in al, 92h
	or al, 00000010b
	out 92h, al
	
	; 准备切换到保护模式
	mov eax, cr0
	or eax, 1
	mov cr0, eax
		
	; 真正进入保护模式
	jmp dword SelectorCode32:0		;执行这一句会把SelectorCode32 装入cs, 并跳转到Code32Selector:0 处

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:			; 从保护模式跳回到实模式就到这里
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	
	mov sp, [_wSPValueInRealMode]
	
	in al, 92h			; 
	and al, 
	out 92h, al
	
	;sti				

	mov ax, 4c00h		;
	int 21h				;
; END of [SECTION .s16]

[SECTION .s32]
[BITS	32]

LABEL_SEG_CODE32:
	mov ax, SelectorData
	mov ds, ax				;数据段选择子
	mov es, ax
	mov ax, SelectorVideo
	mov gs,	ax				;视频段选择子
	
	mov ax, SelectorStack
	mov ss, ax
	mov esp, TopOfStack
	
	call Init8259A
	int 080h
	jmp $

	; 下面显示一个字符串
	push szPMMessage
	call DispStr
	add esp, 4

	push szMemChkTitle
	call DispStr
	add esp, 4

	call DispMemSize		;显示内存信息
	
	call PagingDemo			;演示改变页目录的效果
	
	; 到此停止
	jmp SelectorCode16:0

; Init8259 ---------------------------------------
Init8259A:
	mov al, 011h
	out 020h, al		;主8259， ICW1,
	call io_delay

	out 0A0h, al		;从8259， ICW1,
	call io_delay
	
	mov al, 020h		;IRQ0 对应中断向量 0x20
	out 021h, al		;主8259, ICW2
	
	mov al, 028h;		;IRQ8 对应中断向量 0x28
	out 0A1h, al		;从8259, ICW2
	
	mov al, 004h		;IR2 对应从8259
	out 021h, al		;主8259， ICW3

	mov al, 002h		;对应主8259的IR2
	out 0A1h, al		;从8259， ICW3
	call io_delay
	
	mov al, 001h
	out 021h, al		;主8259, ICW4
	call io_delay

	out 0A1h, al		;从8259, ICW4
	call io_delay

	mov al, 11111110b	;仅仅开启定时中断
	;mov al, 11111111b	;屏蔽主8259所以中断
	out 021h, al		;总8259， OCW1
	
	mov al, 11111111b	;屏蔽从8259所以中断
	out 0A1h, al
	call io_delay

	ret
; Init8259A -------------------------------------------

io_delay:
	nop
	nop
	nop
	nop
	ret

_UserIntHandle:
UserIntHandle equ _UserIntHandler - $$
	mov ah, 0Ch				; 0000: 黑底 1100: 红字
	mov al, 'I'
	mov [gs:((80 * 00 + 70) * 2)], ax	;屏幕第0 行, 第70列
	iretd

_SpuriousHandler:
SpuriousHandler equ _SpuriousHandler - $$
	mov ah, 0Ch
	mov al, '!'
	mov [gs:((80 * 0 + 75) * 2)], ax	;屏幕第0行， 第75列
	iretd

; 启动分页机制 ----------------------------------------------
SetupPaging:
	; 根据内存大小计算应初始化多少PDE以及多少页表
	xor edx, edx
	mov eax, [dwMemSize]
	mov ebx, 400000h		; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
	div ebx
	mov ecx, eax	;此时 ecx 为页表的格式, 也即 PDE 应该的个数
	test edx, edx
	jz .no_remainder
	inc ecx			; 如果余数不为0就需要增加一个页表
.no_remaindex:
	mov [PageTableNumber], ecx	;暂存页表个数
	
	; 为简化处理, 所以线性地址对应相等的物理地址, 并且不考虑内存空间
	
	; 首先初始化页目录
	mov ax, SelectorFlatRw
	mov es, ax
	mov edi, PageDirBase0	;此段首地址为PageDirBase0
	xor eax, eax
	mov eax, PageTblBase0	|PG_P |PG_USU |PG_RWW
.1:
	stosd
	add eax, 4096		;为了简化, 所以页表在内存中是连续的
	loop .1

	; 再初始化所以页表
	mov eax, [PageTableNumber]	;页表个数
	mov ebx, 1024	;每个页表1024 个 PTE
	mul ebx
	mov ecx, eax	;PTE 个数 = 页表个数 * 1024
	mov edi, PageTblBase0 ;此段首地址为PageTblBase0
	xor eax, eax
	mov eax, PG_P | PG_USU | PG_RWW

.1:
	stosd
	add eax, 40096	; 每一页指向4K的空间
	loop .2

	mov eax, PageDirBase0
	mov cr3, eax
	mov eax, cr0
	or eax, 80000000h
	mov cr0, eax
	jmp short .3

.3:	
	nop
	
	ret
; 分页机制启动完成


;------------------------------------------------------------------

PagingDemoProc:
OffsetPagingDemoProc 	equ PagingDemoProc - $$
	mov eax, LinearAddrDemo
	call eax
	retf
LenPagingDemoAll	equ $ - PagingDemoProc

foo:
OffsetFoo	equ foo - $$
	mov ah, 0Ch			; 0000: 黑底 1100：红底
	mov al, 'F'
	mov [gs:((80 * 17 + 0 ) * 2)], ax ; 屏幕第17行， 第0列
	mov al, 'o'
	

; 显示内存信息 ---------------------------------------------------
DispMemSize:
	push esi
	push edi
	push ecx

	mov esi, MemChkBuf
	mov ecx, [dwMCRNumber]	
.loop:
	mov edx, 5
	mov edi, ARDStruct
.1:
	push dword [esi]
	call DispInt
	pop eax
	stosd
	add esi, 4
	dec edx
	cmp edx, 0
	jnz .1
	call DispReturn
	cmp dword [dwType], 1
	jne .2
	mov eax, [dwBaseAddrLow]
	add eax, [dwLengthLow]
	cmp eax, [dwMemSize]
	jb .2
	mov [dwMemSize], eax
.2:
	loop .loop

	call DispReturn
	push szRAMSize
	call DispStr
	add esp, 4

	push dword [dwMemSize]	
	call DispInt
	add esp, 4
	
	pop ecx
	pop edi
	pop esi
	ret
;----------------------------------------------------------------

%include "lib.inc"	; 库函数

SegCode32Len 	equ $ - LABEL_SEG_CODE32
;END of [SECTION .s32]

; 16 位代码段, 由32位代码段跳入, 跳出后到实模式
[SECTION .s16code]
ALIGN 32
[BITS 	16]
LABEL_SEG_CODE16:
	; 跳回到实模式
	mov ax, SelectorNormal
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	
	mov eax, cr0
	add eax, 7FFFFFFEh		;PE=0, PG=0
	mov cr0, eax
	
LABEL_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY	;段地址会在程序开始处被设置成正确的值
	
Code16Len 	equ $ - LABEL_SEG_CODE16

; END of [SECTION .s16code]






