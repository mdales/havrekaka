BASIC=Makefile

all: $(BASIC) havrekaka.vfd

# bootstrap.iso: $(BASIC) bootstrap.bin cdiso/bootstrap.vfd
# 	dd status=noxfer conv=notrunc if=bootstrap.bin of=cdiso/bootstrap.vfd
# 	# dd status=noxfer conv=notrunc if=test.pcx of=cdiso/bootstrap.vfd bs=512 seek=1
# 	# dd status=noxfer conv=notrunc if=payload.elf of=cdiso/bootstrap.vfd bs=512 seek=1
# 	mkisofs -o bootstrap.iso -b bootstrap.vfd cdiso/

bin/stövelrem.bin: $(BASIC) src/stövelrem.asm
	mkdir -p bin
	nasm -f bin -o bin/stövelrem.bin src/stövelrem.asm

bin/kärna.bin: $(BASIC) src/kärna/kärna.asm src/kärna/gdt.asm src/kärna/vga_text.asm
	mkdir -p bin
	nasm -f bin -o bin/kärna.bin src/kärna/kärna.asm

havrekaka.vfd: $(BASIC) bin/stövelrem.bin bin/kärna.bin
	rm -f bin/havrekaka.vfd
	dd if=/dev/zero of=bin/havrekaka.vfd bs=1k count=1440
	dd status=noxfer conv=notrunc if=bin/stövelrem.bin of=bin/havrekaka.vfd
	dd status=noxfer conv=notrunc if=bin/kärna.bin of=bin/havrekaka.vfd bs=512 seek=1

clean:
	rm -f bin/*
