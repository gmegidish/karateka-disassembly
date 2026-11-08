all: verify

SRC_FILES := $(wildcard src/*.asm)

build/NEW.EXE: $(SRC_FILES) | build
	nasm -f bin -i src/ src/karateka.asm -o build/NEW.EXE

build:
	mkdir -p build

verify: build/NEW.EXE
	cmp build/NEW.EXE disk/KARATEKA.EXE && echo "MATCH OK" || echo "MISMATCH!"

hebrew: $(SRC_FILES)
	nasm -f bin -DHEBREW -i src/ src/karateka.asm -o disk/HEBREW.EXE

hebrew-end: $(SRC_FILES)
	nasm -f bin -DHEBREW -DSKIP_TO_END -i src/ src/karateka.asm -o disk/HEBEND.EXE

clean:
	rm -f build/NEW.EXE

.PHONY: all verify clean hebrew hebrew-end
