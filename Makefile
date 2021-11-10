BASIC=Makefile

all: $(BASIC) havrekaka.vfd

bin/stövelrem.bin: $(BASIC) src/stövelrem.asm
	mkdir -p bin
	nasm -f bin -o bin/stövelrem.bin src/stövelrem.asm

bin/kärna.bin: $(BASIC) src/kärna/*.asm bin/strings.asm
	mkdir -p bin
	nasm -f bin -o bin/kärna.bin src/kärna/kärna.asm

havrekaka.vfd: $(BASIC) bin/stövelrem.bin bin/kärna.bin bin/bakafs disk.json bin/font.t
	bin/bakafs disk.json bin/havrekaka.vfd

bin/bakafs: $(BASIC) verktyg/bakafs/main.go
	go build -o bin/bakafs verktyg/bakafs/main.go

bin/psf2typsnitt: $(BASIC) verktyg/psf2typsnitt/main.go
	go build -o bin/psf2typsnitt verktyg/psf2typsnitt/main.go

bin/strings2asm: $(BASIC) verktyg/strings2asm/main.go
	go build -o bin/strings2asm verktyg/strings2asm/main.go

bin/strings.asm: $(BASIC) bin/strings2asm resurser/se.strings
	bin/strings2asm resurser/se.strings bin/strings.asm

bin/font.t: $(BASIC) bin/psf2typsnitt ThirdParty/tamzen-font/psf/TamzenForPowerline10x20.psf
	bin/psf2typsnitt ThirdParty/tamzen-font/psf/TamzenForPowerline10x20.psf bin/font.t

clean:
	rm -f bin/*
