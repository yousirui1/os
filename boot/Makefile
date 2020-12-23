a.img:
	nasm boot.asm  -o boot.bin
	sudo dd if=boot.bin of=a.img bs=512 count=1

img:
	sudo mount freedos.img dos
	sudo cp boot.bin dos
	sudo umount dos
	
clean:
	rm -f a.img boot.bin
