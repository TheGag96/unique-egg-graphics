#!/bin/bash

set -e

original_eggdata=egg_data_vanilla.narc
patched_eggdata=egg_data_patched.narc

cd PokEditor # PokeEditor doesn't work unless you run it from its containing directory

extracted_folder_eggdata=$(basename -s .narc $original_eggdata)
rm -rf extracted/$extracted_folder_eggdata     # just in case - PokEditor will complain if it exists
rm -f  ../$patched_eggdata   # ditto
echo ../$original_eggdata   | java -jar PokEditor.jar narc unpack

# match with constant in Hijack_Include.s!
FIRST_CUSTOM_EGG_PALETTE=12
FIRST_CUSTOM_EGG_GRAPHIC=505

# normal egg sprite
cp ../egg_data/gfx/normal.sprite.ncgr "extracted/$extracted_folder_eggdata/11.ncgr"

# copy palettes for all 493 pokemon into narc
for id in {1..493}
do
  cp ../egg_data/pals/$id.nclr "extracted/$extracted_folder_eggdata/$(($id+$FIRST_CUSTOM_EGG_PALETTE-1)).nclr"
done

# must match order in Hijack_SpecialPokemon.s
special_pokemon=(
  togepi
)

# copy pokemon graphics into proper narc locations
counter=$FIRST_CUSTOM_EGG_GRAPHIC
for pokemon in $special_pokemon
do
  cp ../egg_data/gfx/$pokemon.sprite.ncgr  "extracted/$extracted_folder_eggdata/$(($counter)).ncgr"
  cp ../egg_data/gfx/$pokemon.hatching.bin "extracted/$extracted_folder_eggdata/$(($counter+1)).bin"
  counter=$((counter+2))
done

echo -e "$extracted_folder_eggdata\n../$patched_eggdata" | java -jar PokEditor.jar narc pack
# rm -rf extracted/$extracted_folder_eggdata
cd ../