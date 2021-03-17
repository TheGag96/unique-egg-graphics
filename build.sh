#!/bin/bash

set -e

original_arm9bin=arm9_hg_vanilla.bin
patched_arm9bin=arm9_hg_patched.bin

original_overlay95bin=overlay95_hg_vanilla.bin
patched_overlay95bin=overlay95_hg_patched.bin

original_customoverlaynarc=custom_overlay_hg_vanilla.narc
patched_customoverlaynarc=custom_overlay_hg.narc
customoverlay_size=$((32*1024))

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
compile_asm Hijack_SpecialPokemon.s

# compile binary patch tool and hijack branch maker tools
dmd binpatch.d
dmd makebl.d

# prepare patched output .bin file
cp $original_arm9bin      $patched_arm9bin
cp $original_overlay95bin $patched_overlay95bin

# use Mikelan98's and Nomura's patches to load file a/0/2/8/0.nclr at startup, which can be used as a place for free code space
# see https://pokehacking.com/tutorials/ramexpansion/
echo FC B5 05 48 C0 46 1C 21 00 22 02 4D A8 47 00 20 03 21 FC BD 09 75 00 02 00 80 3C 02 | ./binpatch $patched_arm9bin 110334
echo 0F F1 30 FB | ./binpatch $patched_arm9bin CD0

# create blank file to put code into
fallocate -l $customoverlay_size tmp_custom_overlay

# extract compiled machine code and patch them to specific locations

function patch_code {
  eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text $1.o temp_bin
  od -An -t x1 temp_bin | ./binpatch tmp_custom_overlay $2
}

patch_code Hijack_PkmnPtrSave    1010
patch_code Hijack_ColoredEggs    1030
patch_code Hijack_Hatching       10A0
patch_code Hijack_SpecialPokemon 10F0

# put custom overlay file into the narc that will contain it
# this involves unpacking the vanilla narc file, putting in our file into the extracted folder, and repacking
cd PokEditor # PokeEditor doesn't work unless you run it from its containing directory
extracted_folder=$(basename -s .narc $original_customoverlaynarc)
rm -rf extracted/$extracted_folder   # just in case - PokEditor will complain if it exists
rm -f  ../$patched_customoverlaynarc # ditto
echo ../$original_customoverlaynarc | java -jar PokEditor.jar narc unpack
mv ../tmp_custom_overlay extracted/$extracted_folder/0.nclr
echo -e "$extracted_folder\n../$patched_customoverlaynarc" | java -jar PokEditor.jar narc pack
rm -rf extracted/$extracted_folder
cd ../

# hijack GetPkmnData to jump to Hijack_PkmnPtrSave.s
./makebl 0206E546 023C9010 | ./binpatch $patched_arm9bin 6E546
./makebl 0206E646 023C9010 | ./binpatch $patched_arm9bin 6E646

# hijack sprite arbitration code to jump to Hijack_ColoredEggs.s
./makebl 02070384 023C9030 | ./binpatch $patched_arm9bin 70384
echo C046 C046 C046 C046 C046 | ./binpatch $patched_arm9bin 70388 # nop out replaced code

# hijack egg hatch animation code to jump to Hijack_Hatching.s
./makebl 021E5F02 023C90A0 | ./binpatch $patched_overlay95bin 602

rm temp_bin