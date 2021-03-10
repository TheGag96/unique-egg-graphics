.thumb

Hijack_PkmnPtrSave: @ hook at 0x74476 and 0x74576
  push {lr}
  push {r0, r1}

  @ store off last read Pokemon data pointer
  ldr r1, =0x020501DC @ location of "free ram"
  str r5, [r1, #0]

  @ restore old code
  pop {r0, r1}
  mov r4, r1
  mov r6, r2

  pop {pc}
