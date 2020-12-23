
org 0100h
	jmp LABEL_START			

%include "fat12hdr.inc"
%include "load.inc"
%include "pm.inc"


BaseOfStack equ 0100h

LABEL_START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack
	
	mov dh, 0
	call DispStrRealMode
