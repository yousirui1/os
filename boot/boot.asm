; boot 程序 从FAT16 实模式下找到LOADER.BIN 程序 跳转并执行

%define _BOOT_DEBUG_	;dos 环境

%ifdef _BOOT_DEBUG_
	org 0100h
%else
	org 07c00h
%endif

;============================================================
%ifdef _BOOT_DEBUG_
BaseOfStack		equ 0100h		;调试状态下堆栈基地址(栈底, 从这个位置向低地址生长)
%else
BaseOfStack		equ 07c00h		;Boot状态下堆栈基地址(栈底, 从这个位置向低地址生长)
%endif

%include "../include/load.inc"
;==============================================================

	jmp short LABEL_START		; Start to boot
	nop							; 这个nop 不可少

%include "../include/fat12hdr.inc"

LABEL_START:
	mov ax, cs					 
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack

	call CleanScreen

	xor ah, ah			;┓
	xor dl, dl			;┣ 软驱复位 采用有软驱存储数据
	int 13h				;┛
	
	; 在 A 盘 的根目录搜索LOADER.BIN
	mov word [wSectorNo], SectorNoOfRootDirectory	;  ds:[wSectorNo] u16 wSectorNo = SectorNoOfRootDirectory = 19
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:						; wRootDirSizeForLoop = 14
	cmp word [wRootDirSizeForLoop], 0	;			if(wRootDirSizeForLoop == 0)			//根目录区总大小14个扇区
	jz LABEL_NO_LOADERBIN				; 				goto LABEL_NO_LOADERBIN
	dec word [wRootDirSizeForLoop]		;			wRootDirSizeForLoop--;
	mov ax, BaseOfLoader
	mov es, ax							; es<- BaseOfLoader
	mov bx, OffsetOfLoader				; bx<- OffsetOfLoader es:bx = BaseOfLoader:OffsetOfLoader
	mov ax, [wSectorNo]					; ax<- Root Directory 中的 Sector 号
	mov cl, 1							; 一个扇区
	call ReadSector						; 	es:bx =	ReadSecotr(BaseOfLoader, OffsetOfLoader, 1);	//读取一个扇区
	
	mov si, LoaderFileName				; ds:si -> "LOADER  BIN"
	mov di, OffsetOfLoader				; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld									; DF = 0 方向标志位
	mov dx, 10h							; 	dx = 10h
LABEL_SEARCH_FOR_LOADERBIN:				; 
	cmp dx, 0							;	if(dx == 0)
	jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR ; 	goto LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec dx								;	dx --;
	mov cx, LoaderFileLength 			; 	cx = 11
LABEL_CMP_FILENAME:						;  
	cmp cx, 0							;	 if(cx == 0)
	jz LABEL_FILENAME_FOUND				;	  	goto LABEL_FILENAME_FOUND
	dec cx								;	 cx --;
	lodsb								; 	 mov al, [esi]  inc esi  // 从 ei 一个字节取出到al 里面
	cmp al, byte [es:di]				;	 if(memcmp(al, [es:di] == 0)
	jz LABEL_GO_ON						;		goto LABEL_GO_ON
	jmp LABEL_DIFFERENT					;	 else
										; 		goto LABEL_DIFFERENT
LABEL_GO_ON:
	inc di								;	di++
	jmp LABEL_CMP_FILENAME				;	goto LABEL_CMP_FILENAME

LABEL_DIFFERENT:
	and di, 0FFE0h 						;   else ┓  di &= E0 为了让它指向本条目开头
	add di, 20h							;		 ┃	
	mov si, LoaderFileName				;		 ┣	di += 20h 下一个目录条目
	jmp LABEL_SEARCH_FOR_LOADERBIN		;		 ┛

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:		;  一个扇区搜索完 下一个扇区
	add word [wSectorNo], 1				;
	jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:						; 没找到文件
	mov dh, 2							; 显示str[2]	"No LOADER."
	call DispStr						;
%ifdef _BOOT_DEBUG_
	mov ax, 4c00h						; ┓
	int 21h								; ┛ 没找到LOADER.BIN, 回到 DOS
%else
	jmp $								; 死循环在着
%endif
	

LABEL_FILENAME_FOUND:					; 比较11个字符都成功 找到LOADER.BIN 
    mov ax, RootDirSectors
    and di, 0FFE0h      ; di -> 当前条目的开始
    add di, 01Ah        ; di -> 首 Sector
    mov cx, word [es:di]
    push    cx          ; 保存此 Sector 在 FAT 中的序号
    add cx, ax
    add cx, DeltaSectorNo   ; 这句完成时 cl 里面变成 LOADER.BIN 的起始扇区号 (从 0 开始数的序号)
    mov ax, BaseOfLoader
    mov es, ax          ; es <- BaseOfLoader
    mov bx, OffsetOfLoader  ; bx <- OffsetOfLoader  于是, es:bx = BaseOfLoader:OffsetOfLoader = BaseOfLoader*10h+ OffsetOfLoader
    mov ax, cx          ; ax <- Sector 号

	
LABEL_GOON_LOADING_FILE:
	push ax				; ┓
	push bx				; ┃
	mov ah, 0Eh			; ┃
	mov al, '.'			; ┃ 每读一个扇区就"Booting "后面打一个点 
	mov bl, 0Fh			; ┃
	int 10h				; ┃
	pop bx				; ┃
	pop ax				; ┛
	
	mov cl, 1
	call ReadSector
	pop ax				; 取出此 Sector 在 FAT 中的序号
	call GetFATEntry
	cmp ax, 0FFFh
	jz LABEL_FILE_LOADED
	push ax				; 保存Sector 在FAT 中的序号
	mov dx, RootDirSectors
	add ax, dx
	add ax, DeltaSectorNo
	add bx, [BPB_BytsPerSec]
	jmp LABEL_GOON_LOADING_FILE

LABEL_FILE_LOADED:
	mov dh, 1			; "Ready."
	call DispStr		; 显示str[1]

	jmp BaseOfLoader:OffsetOfLoader	;这一句正式跳转到已加载到内存中的 LOADER.BIN 的开始处
									;开始执行 LOADER.BIN 的代码
									;Boot Sector 的使命到此结束

;==================================================
;变量
;-------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数, 在循环中会递减至0
wSectorNo			dw	0				; 要读取的扇区号
bOdd				db	0				; 奇数还是偶数

;=============================================
;字符串
;----------------------------------------------
LoaderFileName      db "LOADER  BIN", 0
LoaderFileLength	equ 11
;为了简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength       equ 9
BootMessage:        db "Booting  "  ; 9 字节不够则用空格补齐, 序号0 
Message1:           db "Ready.   "  ; 9 字节不够则用空格补齐, 序号1 
Message2:           db "No LOADER"  ; 9 字节不够则用空格补齐, 序号2 
;=======================================================

;-----------------------------------------------
; 函数名: ReadSector(start, offset cnt)
;-----------------------------------------------
; 作用: 
;		从第ax 个Sector开始 将cl 个Sector 读入 es:bx 中
ReadSector:
    ; -----------------------------------------------------------------------
    ; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
    ; -----------------------------------------------------------------------
    ; 设扇区号为 x
    ;                          ┌ 柱面号 = y >> 1
    ;       x           ┌ 商 y ┤
    ; -------------- => ┤      └ 磁头号 = y & 1
    ;  每磁道扇区数     │
    ;                   └ 余 z => 起始扇区号 = z + 1
	push bp
	mov bp, sp
	sub esp, 2				; 开辟出2个字节的堆栈区域保存要读入的扇区 byte [bp - 2] sector[2] = cl

	mov byte [bp - 2], cl	; 
	push bx					; 保存 bx
	mov bl, [BPB_SecPerTrk]	; bl 除数
	div bl					; (ax / bl = y(al)) + z(ah)
	inc ah					; z ++
	mov cl, ah				; cl <- 其实扇区号
	mov dh, al				; dh <- y
	shr al, 1				; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov ch, al				; ch <- 柱面号
	and dh, 1				; dh & 1 = 磁头号
	pop bx					; 回复bx 

	mov dl, [BS_DrvNum]		; 驱动器号(0 表示 A盘)
.GoOnReading:
	mov ah, 2				; 读
	mov al, byte [bp-2]		; 读al个扇区
	int 13h
	jc .GoOnReading			; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止
	
	add esp, 2				; 恢复开辟的 2个字节
	pop bp

	ret

;------------------------------------------------
; 函数名: DispStr
;-----------------------------------------------
; 作用: 
;      显示一个字符串常量, 函数开始时dh 中应该是字符串序号(0-based)
DispStr:
	mov ax, MessageLength		;  MessageLength
	mul dh						;  (ax)offset = (dh)i * (ax)MessageLength 
	add ax, BootMessage			;  message[i] = *BootMessage + offset

	mov bp, ax					;
	mov ax, ds					; es <- ds
	mov es, ax					; es:bp = 串地址 cx = 串长度

	mov cx, MessageLength
	mov ax, 01301h				; (ah)01 文字 + (al)13显示字符串
	mov bx, 0007h				; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov dl, 0					;
	
	int 10h
	ret


;---------------------------------------------------
; 函数名: CleanScreen
;---------------------------------------------------
; 作用:
; 		清空显示屏幕
CleanScreen
	mov ax, 0600h		; 屏幕初始化或上卷 AL=0 全屏幕
	mov bx, 0700h		; 黑底白字(BL = 07h)
	mov cx, 0			; 左上角:(0, 0)
	mov dx, 0184fh		; 右下角:(80, 50)

	int 10h	
	ret

;----------------------------------------------------
; 函数名: GetFATEntry
;-----------------------------------------------------
; 作用:
;		找到序号为ax的Sector 在FAT中的条目, 结果放在ax 中
;		需要注意, 中间需要读取FAT的扇区到es:bx 出, 所以函数一开始保存es和bx
GetFATEntry:
    push    es
    push    bx
    push    ax
    mov ax, BaseOfLoader    ; ┓
    sub ax, 0100h       ; ┣ 在 BaseOfLoader 后面留出 4K 空间用于存放 FAT
    mov es, ax          ; ┛
    pop ax
    mov byte [bOdd], 0
    mov bx, 3
    mul bx          ; dx:ax = ax * 3
    mov bx, 2
    div bx          ; dx:ax / 2  ==>  ax <- 商, dx <- 余数
    cmp dx, 0
    jz  LABEL_EVEN
    mov byte [bOdd], 1
LABEL_EVEN:;偶数
    xor dx, dx          ; 现在 ax 中是 FATEntry 在 FAT 中的偏移量. 下面来计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
    mov bx, [BPB_BytsPerSec]
    div bx          ; dx:ax / BPB_BytsPerSec  ==>   ax <- 商   (FATEntry 所在的扇区相对于 FAT 来说的扇区号)
                    ;               dx <- 余数 (FATEntry 在扇区内的偏移)。
    push    dx
    mov bx, 0           ; bx <- 0   于是, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h
    add ax, SectorNoOfFAT1  ; 此句执行之后的 ax 就是 FATEntry 所在的扇区号
    mov cl, 2
    call    ReadSector      ; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界发生错误, 因为一个 FATEntry 可能跨越两个扇区
    pop dx
    add bx, dx
    mov ax, [es:bx]
    cmp byte [bOdd], 1
    jnz LABEL_EVEN_2
    shr ax, 4
LABEL_EVEN_2:
    and ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

    pop bx
    pop es
    ret

times 510-($-$$) db 0
	dw 0xaa55

