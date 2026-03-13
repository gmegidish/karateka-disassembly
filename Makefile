all: verify

build/NEW.EXE: src/karateka.asm | build
	nasm -f bin src/karateka.asm -o build/NEW.EXE

build:
	mkdir -p build

verify: build/NEW.EXE
	cmp build/NEW.EXE disk/KARATEKA.EXE && echo "MATCH OK" || echo "MISMATCH!"

clean:
	rm -f build/NEW.EXE

.PHONY: all verify clean
