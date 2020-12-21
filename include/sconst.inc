; sconst.inc
;

P_STACKBASE	equ	0
GSREG		equ P_STACKBASE
;FSREG		equ P_STACKBASE
;ESREG		equ P_STACKBASE
;DSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
;GSREG		equ P_STACKBASE
			

TSS3_S_SP0	equ 4

INT_M_CTL	equ 0x20			;I/O port for interrupt controller <Master>
INT_M_CTLMASK	equ 0x21		;setting bits in this port disables ints <Master>
INT_S_CTL	equ 0xA0			;I/O port for second interrupt controller <Slave>
INT_S_CTLMASK	equ 0xA1		;setting bits in this port disable ints <Slave>

EOI			equ 0x20

;以下选择子值必须与protect.h 中保持一致 !!
SELECTOR_FLAT_C		equ 0x08		; LOADER 里面已经确定了
SELECTOR_TSS		equ 0x20		; TSS 从外层跳到内存时SS 和 ESP 的值从里面获取
SELECTOR_KERNEL_CS	equ	SELECTOR_FLAT_C

