.thumb

Hijack_Hatching: @ hook at overlay 119, 0x79E (0x021D151E)
  push {lr}
  push {r2-r4}

  ldr r0, =0x020501DC @ location of "free ram" area
  ldr r0, [r0]        @ contains pointer to last read pkmn data

  @ call GetBoxPkmnData to get the actual species ID of the Pokemon
  mov r1, #5
  mov r2, #0
  ldr r4, =0x02074571
  blx r4

  @ set up palette narc ID, index by species ID
  mov r1, r0
  add r1, r1, #11

  @@@@
  @ species-specific special cases
  @@@@

  ldr r3, =175  @ togepi
  cmp r0, r3
  beq .togepi

  .normal:

  @ load image narc id (egg)
  mov r0, #4
  b .end

  .togepi:

  @ load image narc id (togepi egg)
  ldr r0, =748

  .end:

  @ restore old code
  pop {r2-r4}
  add r3, r3, #8  @ advance 8 bytes as the old ldmia instruction did
  stmia r2!,{r0, r1}

  pop {pc}
