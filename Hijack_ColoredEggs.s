.thumb

.include "Hijack_Include.s"

Hijack_ColoredEggs: @ hook at 0x70384. nop out 0x70388-0x70390
  push {lr}
  push {r0, r1, r2, r3, r4}

  ldr r0, =LAST_READ_SPECIES_ID @ location of "free ram" area
  ldr r0, [r0]                  @ contains pointer to last read pkmn data

  @ call GetBoxPkmnData to get the actual species ID of the Pokemon
  mov r1, #5
  mov r2, #0
  ldr r4, =0x0206E641
  blx r4

  @ write file id for most likely case (egg_data.narc / a/1/1/5)
  mov r1, #0x73
  strh r1, [r5, #0]

  @ set up palette narc ID, index by species ID
  mov r1, #FIRST_CUSTOM_EGG_PALETTE
  add r2, r0, r1
  sub r2, #1

  @ manaphy is VERY special and can just load from where it normally is
  @ (pl_otherpoke.narc)
  ldr r1, =490  @ manaphy
  cmp r0, r1
  beq .manaphy

  @ begin searching in species-specific special cases list
  ldr r1, =SPECIAL_POKEMON_TABLE
  mov r4, #0

  .special_pokemon_loop_start:

  @ jump out if end of table found
  ldrh r3, [r1]
  cmp r3, #0
  beq .normal

  @ jump out if pokemon has a custom graphic
  cmp r0, r3
  beq .special

  add r1, #2
  add r4, #1
  b .special_pokemon_loop_start

  .special:

  ldr r1, =FIRST_CUSTOM_EGG_GRAPHIC
  lsl r4, #1
  add r1, r4  @ summary/box sprite graphic comes first
  b .end

  .normal:

  @ load image narc id (egg)
  mov r1, #11
  b .end

  .manaphy:

  @ write file id containing manaphy (pl_otherpoke.narc)
  mov r1, #0x72
  strh r1, [r5, #0]

  @ load image narc id (manaphy egg)
  mov r1, #0x85

  @ load palette narc id
  mov r2, #0xE3

  .end:

  @ write image and palette narc id (indexed by species ID)
  strh r1, [r5, #2]
  strh r2, [r5, #4]

  pop {r0, r1, r2, r3, r4}
  pop {pc}
