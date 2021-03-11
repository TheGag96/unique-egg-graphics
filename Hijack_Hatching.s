.thumb

.include "Hijack_Include.s"

Hijack_Hatching: @ hook at overlay 119, 0x79E (0x021D151E)
  push {lr}
  push {r2-r4}

  ldr r0, =LAST_READ_SPECIES_ID @ location of "free ram" area
  ldr r0, [r0]                  @ contains pointer to last read pkmn data

  @ call GetBoxPkmnData to get the actual species ID of the Pokemon
  mov r1, #5
  mov r2, #0
  ldr r4, =0x02074571
  blx r4

  @ set up palette narc ID, index by species ID
  mov r1, r0
  add r1, #FIRST_CUSTOM_EGG_PALETTE
  sub r1, #1

  @@@@
  @ species-specific special cases
  @@@@

  ldr r2, =SPECIAL_POKEMON_TABLE
  mov r4, #0

  .special_pokemon_loop_start:

  ldrh r3, [r2]
  cmp r3, #0
  beq .normal

  cmp r0, r3
  beq .special

  add r2, #2
  add r4, #1
  b .special_pokemon_loop_start

  .special:

  ldr r0, =FIRST_CUSTOM_EGG_GRAPHIC
  lsl r4, #1
  add r0, r4
  add r0, #1  @ hatching animation graphic comes second
  b .end

  .normal:

  @ load image narc id (egg)
  mov r0, #4
  b .end

  .end:

  @ restore old code
  pop {r2-r4}
  add r3, #8  @ advance 8 bytes as the old ldmia instruction did
  stmia r2!,{r0, r1}

  pop {pc}
