# Unique Egg Graphics for Pokémon Platinum

This mod allows eggs to have a palette swap or custom sprites based on Pokémon species. The way things are set up currently, every species has a custom palette assigned to it, but a table defines species that get a custom graphic as well.

This hack is compatible with the [Individually-Unique Pokémon Colors Mod](https://github.com/TheGag96/individual-color-variation).

If you would like to use this in your own hacks, please feel free to do so!


## Building

1. Install [devkitARM](https://devkitpro.org/wiki/Getting_Started).
2. Install a [D compiler](https://dlang.org/download.html).
3. Use a program like Nitro Explorer 3 to extract `arm9.bin`, `overlay9-119.bin`, and `demo/egg/data/egg_data.narc` from your Platinum ROM.
4. Place them in the root folder of this repo, and name them to `arm9_vanilla.bin`, `overlay119_vanilla.bin`, and `egg_data_vanilla.narc` respectively.
5. Run `./build_egg_data.sh`.
6. Run `./build.sh`.
7. Inject `arm9_patched.bin`, `overlay119_patched.bin`, `egg_data_patched.bin`, and `overlay87_patched.bin` back into `arm9.bin`, `overlay9-119.bin`, and `demo/egg/data/egg_data.narc`, respectively.


## Adding New Palettes

Simply replace the `.nclr` file in `egg_data/pals` corresponding to the species ID of the Pokémon. **Make sure that the palette contains 16 colors!** I think the game and various tools will get upset if there are fewer, for example. When in doubt, base your file off of the other 90-byte palette files currently in that folder.


## Adding New Graphics

* Add the species ID to the table defined in `Hijack_SpecialPokemon.s`. 

  - (**Note: The address of this table is near the limit of the unused space found for inserting this mod. Too many may overflow into data actually used by the game.** This mod thus needs to be reworked in the future to run off a synthetic overlay so that this won't occur.)

* Add the name of the species into the table called `special_pokemon` in `build_egg_data.sh`. An entry such as `togepi`should correspond with two files in `egg_data/gfx/` named `togepi.sprite.ncgr` and `togepi.hatching.bin`.

  - The `.sprite.ncgr` file would be in the exact same format as would be found in `pl_pokegra.narc` or `pl_otherpoke.narc` - you can insert one into a dummy file using PokeDSPicPlatinum and then extract it with Tinke.

  - The `.hatching.bin` file is modeled after the compressed egg animation image found in `demo/egg/data/egg_data.narc`, subfile 4.

  - Getting the graphics data of both images synced up with the single palette can be a little tricky... I'm still not sure yet what the most streamlined method for doing this is. Experiment and send me a message or write up an issue if you have a good way!


## How It Works

We basically shove a bunch of new stuff into `demo/egg/data/egg_data.narc` and change some code to load it!

The new subfiles that are added to the NARC:

```
11  - Normal egg sprite data (ncgr, copied from pl_pokegra.narc)
12  - Bulbasaur egg palette (nclr)
...
504 - Arceus egg palette (nclr)
505 - Special egg #1 sprite (ncgr, same format as pl_pokegra.narc)
506 - Special egg #1 hatching animation (compressed bin, same format as subfile 4)
507 - Special egg #2 sprite
508 - Special egg #2 hatching animation
...
```

A rundown of the code files involved:

* `Hijack_Include.s` - Just some common constants to be included by all other files.

* `Hijack_PkmnPtrSave.s` - * This code is jumped to from hijacks in both [GetPkmnData](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/pokemon_data.c#L517) and [GetBoxPkmnData](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/pokemon_data.c#L612). It just grabs the pointer to the Pokémon data structure passed into these function calls and puts it at `0x020501DC` to be used later by `Hijack_ColoredEggs.s` and `Hijack_Hatching.s`.

* `Hijack_ColoredEggs.s` - Hijacks in the [code arbitrating](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/pokemon_data.c#L2985-L2989) what graphic and palette to use for drawing a Pokémon's sprite, specifically in the case for `494` (ID for a Pokémon egg). It uses the pointer to the last read Pokémon data structure at `0x020501DC` in order to call `GetBoxPkmnData` to find out what Pokémon is inside the egg. The NARC file ID changed to the one for `demo/egg/data/egg_data.narc` (`0x76`). The palette chosen is indexed by species ID from a big block of palette subfiles, starting at subfile 12. The graphic subfile ID is chosen by searching through a table defined in `Hijack_SpecialPokemon.s`, looking for the species ID. If it's found, the position it was found in the list is used as an index into the narc (past all of the palettes) . For Manaphy specifically, instead of doing all of that, we just let it load from its usual location. Code from `0x7614E` to `0x76156` is replaced with NOPs since its functionality is replaced.

* `Hijack_Hatching.s` - Hijacks a function in [overlay 119](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/Misc/119_EggHatch.c#L495), that loads the egg hatching animation spritesheet from `demo/egg/data/egg_data.narc`. It largely does the same stuff as `Hijack_ColoredEggs.s`. Though, no special case is needed for Manaphy, as this code is not reached when it's hatching.

* `Hijack_SpecialPokemon.s` - Table of species that have their own GFX. Each entry is two bytes. The order matters, and must match the `special_pokemon` list in `build_egg_data.sh`. The table must end with a `0`.