#!/bin/bash

set -e

original_arm9bin=arm9_vanilla.bin
patched_arm9bin=arm9_patched.bin

original_overlay119bin=overlay119_vanilla.bin
patched_overlay119bin=overlay119_patched.bin

# original_overlay16bin=overlay16_vanilla.bin
# patched_overlay16bin=overlay16_patched.bin

# original_overlay86bin=overlay86_vanilla.bin
# patched_overlay86bin=overlay86_patched.bin

# original_overlay87bin=overlay87_vanilla.bin
# patched_overlay87bin=overlay87_patched.bin

# compile asm and C files
function compile_c {
  eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math -mthumb -mthumb-interwork -I/opt/devkitpro/libnds/include -DARM9 -c $1 -o $(basename $1 .c).o
}

function compile_asm {
  eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c $1 -o $(basename $1 .s).o
}

compile_asm Hijack_PkmnPtrSave.s
compile_asm Hijack_ColoredEggs.s
compile_asm Hijack_Hatching.s

# compile binary patch tool and hijack branch maker tools
dmd binpatch.d
dmd makebl.d

# prepare patched output .bin file
cp $original_arm9bin       $patched_arm9bin
cp $original_overlay119bin $patched_overlay119bin
# cp $original_overlay16bin $patched_overlay16bin
# cp $original_overlay86bin $patched_overlay86bin
# cp $original_overlay87bin $patched_overlay87bin

# extract compiled machine code and patch them to specific locations

function patch_code {
  eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text $1.o temp_bin
  od -An -t x1 temp_bin | ./binpatch $patched_arm9bin $2
}

patch_code Hijack_PkmnPtrSave 50550
patch_code Hijack_ColoredEggs 50570
patch_code Hijack_Hatching    505E0

# hijack GetPkmnData to jump to Hijack_PkmnPtrSave.s
./makebl 74476 50550 | ./binpatch $patched_arm9bin 74476
./makebl 74576 50550 | ./binpatch $patched_arm9bin 74576

# hijack sprite arbitration code to jump to Hijack_ColoredEggs.s
./makebl 7614A 50570 | ./binpatch $patched_arm9bin 7614A
echo C046 C046 C046 C046 C046 | ./binpatch $patched_arm9bin 7614E # nop out replaced code

# hijack egg hatch animation code to jump to Hijack_Hatching.s
./makebl 021D151E 505E0 | ./binpatch $patched_overlay119bin 79E

rm temp_bin