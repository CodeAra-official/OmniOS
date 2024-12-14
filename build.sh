# asm to bin
mkdir build
nasm -f bin -o build/boot.bin src/Boot/Boot.asm
nasm -f bin -o build/kernel.bin src/kernel.asm

# disk image
dd if=/dev/zero of=build/OmniOS.img bs=512 count=2880
mkfs.fat -F 12 -n "OmniOS" build/OmniOS.img
dd if=build/boot.bin of=build/OmniOS.img conv=notrunc

# Copy files to the image
mcopy -i build/OmniOS.img build/kernel.bin "::kernel.bin"
mcopy -i build/OmniOS.img build/test.txt "::test.txt"
mcopy -i build/OmniOS.img build/system "::system"

# Run the system in QEMU
qemu-system-i386 -boot c -m 256 -fda build/OmniOS.img
