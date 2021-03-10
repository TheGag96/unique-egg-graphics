#!/bin/bash

set -e

original_eggdata=egg_data_vanilla.narc
patched_eggdata=egg_data_patched.narc

original_otherpoke=pl_otherpoke_vanilla.narc
patched_otherpoke=pl_otherpoke_patched.narc

cd PokEditor # PokeEditor doesn't work unless you run it from its containing directory

extracted_folder_eggdata=$(basename -s .narc $original_eggdata)
extracted_folder_otherpoke=$(basename -s .narc $original_otherpoke)

# rm -rf extracted/$extracted_folder_eggdata     # just in case - PokEditor will complain if it exists
# rm -rf extracted/$extracted_folder_otherpoke   # just in case - PokEditor will complain if it exists

rm -f  ../$patched_eggdata   # ditto
rm -f  ../$patched_otherpoke # ditto

# echo ../$original_eggdata   | java -jar PokEditor.jar narc unpack
# echo ../$original_otherpoke | java -jar PokEditor.jar narc unpack

function copy_pals {
  # $1 = folder to copy into
  # $2 = first narc ID of palette list for all pokemon (bulbasaur = 1)

  for id in {1..493}
  do
    cp ../eggpals/$id.nclr "$1/$(($id+$2-1)).nclr"
  done
}

copy_pals extracted/$extracted_folder_eggdata   12
copy_pals extracted/$extracted_folder_otherpoke 254


echo -e "$extracted_folder_eggdata\n../$patched_eggdata"     | java -jar PokEditor.jar narc pack
echo -e "$extracted_folder_otherpoke\n../$patched_otherpoke" | java -jar PokEditor.jar narc pack

# rm -rf extracted/$extracted_folder_eggdata
# rm -rf extracted/$extracted_folder_otherpoke

cd ../