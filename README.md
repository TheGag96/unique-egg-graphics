# Unique Egg Graphics for Pokémon Platinum

This mod allows eggs to have a palette swap or custom sprites based on Pokémon species. The way things are set up currently, every species has a custom palette assigned to it, but a table defines species that get a custom graphic as well.

This hack is compatible with the [Individually-Unique Pokémon Colors Mod](https://github.com/TheGag96/individual-color-variation).

If you would like to use this in your own hacks, please feel free to do so!


## Building

1. Install [devkitARM](https://devkitpro.org/wiki/Getting_Started).
2. Install a [D compiler](https://dlang.org/download.html).
3. Download NSMB Editor. Because the latest version (as of 379) is broken with regard to decompressing overlays, I recommend [this custom version](https://nsmbhd.net/post/53582/) from MeroMero. An [older version](https://nsmbhd.net/download/353/) may work also. For Windows users, [CrystalTile2](https://www.romhacking.net/utilities/818/) may also work.
4. Download [PokeEditor](https://github.com/turtleisaac/PokEditor/releases), extract it into the root folder of this repo, and rename folder that got extracted to `PokEditor`.
5. Open up your ROM in NSMBe (ignoring the error that comes up on load when using MeroMero's build).
6. Under "Tools/Options", select "Decompress ARM9 binary".
7. Under "ROM File Browser", select `arm9.bin`, click "Extract", and save as `arm9_hg_vanilla.bin` in the root folder of this repo.
8. In the `overlay9` folder, select `overlay9_95.bin`, click "Decompress overlay", click "Extract", and save as `overlay95_hg_vanilla.bin`.
9. In the `root/a/0/2` folder, extract file `8` as `custom_overlay_hg_vanilla.narc`.
10. In the `root/a/1/1` folder, extract file `5` as `egg_data_hg_vanilla.narc`.
11. On the command line, run `./build.sh`, then `./build_egg_data.sh`.
12. In NSMBe, reinsert `arm9_hg_patched.bin`, and and `overlay95_hg_patched.bin` back into `arm9.bin` and `overlay9_95.bin`, respectively. For `arm9.bin`, you may need to hit "Decompress ARM9 Binary" to correctly insert it (not sure).
13. Reinsert `custom_overlay_hg.narc` into `root/a/0/2/8`.
14. Reinsert `egg_data_hg_patched.narc` into `root/a/1/1/5`.


## Adding New Palettes

Simply replace the `.nclr` file in `egg_data/pals` corresponding to the species ID of the Pokémon. **Make sure that the palette contains 16 colors!** I think the game and various tools will get upset if there are fewer, for example. When in doubt, base your file off of the other 90-byte palette files currently in that folder.


## Adding New Graphics

* Add the species ID to the table defined in `Hijack_SpecialPokemon.s`. 

* Add the name of the species into the table called `special_pokemon` in `build_egg_data.sh`. An entry such as `togepi`should correspond with two files in `egg_data/gfx/` named `togepi.sprite.ncgr` and `togepi.hatching.bin`.

  - The `.sprite.ncgr` file would be in the exact same format as would be found in `pl_pokegra.narc` or `pl_otherpoke.narc` - you can insert one into a dummy file using PokeDSPicPlatinum and then extract it with Tinke.

  - The `.hatching.bin` file is modeled after the compressed egg animation image found in `demo/egg/data/egg_data.narc`, subfile 4.

  - Getting the graphics data of both images synced up with the single palette can be a little tricky... I'm still not sure yet what the most streamlined method for doing this is. Experiment and send me a message or write up an issue if you have a good way!


## How It Works

We basically shove a bunch of new stuff into `a/1/1/5` (`demo/egg/data/egg_data.narc` in Platinum) and change some code to load it!

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

* `Hijack_PkmnPtrSave.s` - * This code is jumped to from hijacks in both GetPkmnData and GetBoxPkmnData (Platinum equivalent [1](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/pokemon_data.c#L517) and [2](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/pokemon_data.c#L612)). It just grabs the pointer to the Pokémon data structure passed into these function calls and puts it at `0x023C9000` to be used later by `Hijack_ColoredEggs.s` and `Hijack_Hatching.s`.

* `Hijack_ColoredEggs.s` - Hijacks in the code arbitrating ([Platinum equivalent](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/pokemon_data.c#L2985-L2989)) what graphic and palette to use for drawing a Pokémon's sprite, specifically in the case for `494` (ID for a Pokémon egg). It uses the pointer to the last read Pokémon data structure at `0x023C9000` in order to call `GetBoxPkmnData` to find out what Pokémon is inside the egg. The NARC file ID changed to the one for `a/1/1/5` (`0x73`). The palette chosen is indexed by species ID from a big block of palette subfiles, starting at subfile 12. The graphic subfile ID is chosen by searching through a table defined in `Hijack_SpecialPokemon.s`, looking for the species ID. If it's found, the position it was found in the list is used as an index into the narc (past all of the palettes) . For Manaphy specifically, instead of doing all of that, we just let it load from its usual location. Code from `0x70388` to `0x70390` is replaced with NOPs since its functionality is replaced.

* `Hijack_Hatching.s` - Hijacks a function in overlay 95 ([Platinum equivalent](https://github.com/KernelEquinox/PokePlatinum/blob/d4ceb51ccbd9dadd4578afac084d207b3a2a244a/Misc/95_EggHatch.c#L495)), that loads the egg hatching animation spritesheet from `a/1/1/5`. It largely does the same stuff as `Hijack_ColoredEggs.s`. Though, no special case is needed for Manaphy, as this code is not reached when it's hatching.

* `Hijack_SpecialPokemon.s` - Table of species that have their own GFX. Each entry is two bytes. The order matters, and must match the `special_pokemon` list in `build_egg_data.sh`. The table must end with a `0`.


## Credits

* [turtleisaac](https://github.com/turtleisaac) - Idea
* [QuakenPixels](https://www.pixilart.com/art/togepi-egg-101eabef8c91952) - Togepi egg sprite
* [DescendedFromUllr](https://www.deviantart.com/descendedfromullr/art/174-Igglybuff-Egg-Pokemon-Essentials-774854910) - Igglybuff egg sprite
* [LJSTAR](https://twitter.com/LJSTAR_) - Some spriting help
* [Mikelan98, Nomura](https://pokehacking.com/r/20041000) - ARM9 Expansion Subroutine