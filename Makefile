#######################
# Makefile for Orange'S #
#######################


# Entry point of Orange 'S
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc !
ENTRYPOINT = 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET = 0x400


# Programs, flags . etc.
ASM = nasm
DASM = ndisasm
CC = gcc
LD = ld
ASMBFLAGS = -I boot/include/
ASMKFLAGS = -I include/ -f elf
CFLAGS =  -I ./include -m32 -fno-builtin -fno-stack-protector
LDFLAGS = -m elf_i386  -s -Ttext $(ENTRYPOINT) 
DASMFLAGS = -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

ASMFLAGS = -f elf

#This Program
ORANGESBOOT = boot/boot.bin boot/loader.bin
ORANGESKERNEL = kernel.bin

OBJS = main.o global.o printf.o vsprintf.o clock.o
ASMOBJS = syscall.o kliba.o

DASMOUTPUT = kernel.bin.asm

VPATH = .:./include:./lib:./src:./kernel:./boot:

# All Phony Targets
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
nop :
	@echo "why not \`make image' huh? :) "

everything :  $(ORANGESKERNEL)

all : realclean everything

image : realclean everything clean building

clean :
	rm -f $(OBJS)

realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

disasm:
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)
		
# We assume that 'a.img' exists in current folder
buildimg:
	dd 

$(ORANGESKERNEL): $(OBJS) $(ASMOBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS) $(ASMOBJS)

$(OBJS):%.o:%.c
	$(CC) $(CFLAGS)  -c $< -o $@ 

$(ASMOBJS):%.o:%.asm
	$(ASM) $(ASMKFLAGS)  $< -o $@
