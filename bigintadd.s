/*--------------------------------------------------------------------*/
/* bigintadd.s                                                      */
/* Author: Roy Mazumder                                             */
/*--------------------------------------------------------------------*/

    .section .rodata

    .section .data

    .section .bss

    .section .text

/* Return the larger of lLength1 and lLength2
in registers x0 and x1 respectively. */


BigInt_larger:
    cmp x0, x1
    blo retSecond
    ret
retSecond:
    mov x0, x1
    ret

    .size   BigInt_larger, (. - BigInt_larger)
/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */


    .equ    TRUE, 1
    .equ    FALSE, 0

// Must be a multiple of 16
    .equ    BIGINT_STACK_BYTECOUNT, 64
        
    // Local variable stack offsets:
    .equ    LSUMLENGTH, 8
    .equ    LINDEX, 16
    .equ    ULSUM, 24
    .equ    ULCARRY, 32
 
    // Parameter stack offsets:
    .equ    OSUM, 40
    .equ    OADDEND2, 48 
    .equ    OADDEND1, 56  

    // Structure field offsets
    .equ    LLENGTH, 0
    .equ    AULDIGITS, 8

    // Program constants
    .equ MAX_DIGITS, 32768


    .global BigInt_add

BigInt_add:
    // Prolog
    sub sp, sp, BIGINT_STACK_BYTECOUNT
    str x30, [sp]

    // throw parameters in registers into stack
    str x0, [sp, OADDEND1]
    str x1, [sp, OADDEND2]
    str x2, [sp, OSUM]


    //  Determine the larger length: 
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    
    // x0: oAddend1->lLength
    ldr x0, [sp, OADDEND1]
    add x0, x0, LLENGTH
    ldr x0, [x0]
    // x1: oAddend2->lLength
    ldr x1, [sp, OADDEND2]
    add x1, x1, LLENGTH
    ldr x1, [x1]
    // call larger
    bl BigInt_larger

    // lSumLength = x0
    str x0, [SP, LSUMLENGTH]

    //ulCarry = 0;
    mov x0, 0
    str x0, [sp, ULCARRY]

// for loop:  for (lIndex = 0; lIndex < lSumLength; lIndex++)

// lIndex = 0
    mov x0, 0
    str x0, [sp, LINDEX]

mainFor:
    ldr x0, [sp, LINDEX]
    ldr x1, [sp, LSUMLENGTH]
    // if (LINDEX >= LSUMLENGTH) go to end for
    cmp x0, x1
    bhs endFor

// body of for loop

    // ulsum = ulcarry
    ldr x0, [sp, ULCARRY]
    str x0, [sp, ULSUM]

    //ulCarry = 0;
    mov x0, 0
    str x0, [sp, ULCARRY]

    // ulSum += oAddend1->aulDigits[lIndex];

    ldr x0, [sp, ULSUM]
    ldr x1, [sp, OADDEND1]
    add x1, x1, AULDIGITS
    ldr x3, [sp, LINDEX]
    lsl x3, x3, 3
    add x1, x1, x3
    ldr x1, [x1]

    add x0, x0, x1
    str x0, [sp, ULSUM]

    // if (ulSum < oAddend1->aulDigits[lIndex]) 
        // x0: ULSUM, X1: oAddend1->aulDigits[lIndex]

        // if ULSUM >=  oAddend1->aulDigits[lIndex] goto ifNot1
    cmp x0, x1
    bhs ifNot1

    // ulCarry = 1;
    mov x0, 1
    str x0, [sp, ULCARRY]

ifNot1:

    // ulSum += oAddend2->aulDigits[lIndex];
    ldr x0, [sp, ULSUM]
    ldr x1, [sp, OADDEND2]
    add x1, x1, AULDIGITS
    ldr x3, [sp, LINDEX]
    lsl x3, x3, 3
    add x1, x1, x3
    ldr x1, [x1]   

    add x0, x0, x1
    str x0, [sp, ULSUM]

    // if (ulSum < oAddend2->aulDigits[lIndex]) 
        // x0: ULSUM, X1: oAddend2->aulDigits[lIndex]
        // if ULSUM >=  oAddend2->aulDigits[lIndex] goto ifNot2
    cmp x0, x1
    bhs ifNot2

    // ulCarry = 1;
    mov x0, 1
    str x0, [sp, ULCARRY]  

ifNot2:  
    // oSum->aulDigits[lIndex] = ulSum;
        // x0 still contains ULSUM
    ldr x0, [sp, ULSUM]
    ldr x1, [sp, OSUM]
    add x1, x1, AULDIGITS
    ldr x3, [sp, LINDEX]
    lsl x3, x3, 3
    add x1, x1, x3
    str x0, [x1]

    // LINDEX++;
    ldr x0, [sp, LINDEX]
    add x0, x0, 1
    str x0, [sp, LINDEX]
    // go to mainFor
    b   mainFor

endFor:
    //    if (ulCarry == 1) -> if ULCARRY != 1 goto ifNot3
    ldr x0, [sp, ULCARRY]
    cmp x0, 1
    bne ifNot3

    // if (lSumLength == MAX_DIGITS)
        // -> if LSUMLENGTH != MAX_DIGITS goto ifNot4
    ldr x0, [sp, LSUMLENGTH]
    cmp x0, MAX_DIGITS
    bne ifNot4

    // return FALSE --> epilog and return 0
    mov x0, FALSE
    ldr x30, [sp]
    add sp, sp, BIGINT_STACK_BYTECOUNT
    ret

ifNot4:
 // Check for a carry out of the last "column" of the addition.
    // oSum->aulDigits[lSumLength] = 1;
    ldr x0, [sp, LSUMLENGTH]
    lsl x0, x0, 3

    ldr x1, [sp, OSUM]
    add x1, x1, AULDIGITS
    add x1, x1, x0

    mov x2, 1
    str x2, [x1]

    // lSumLength++; x0 contains LSUMLENGTH
    add x0, x0, 1
    str x0, [sp, LSUMLENGTH]

ifNot3:
// Set the length of the sum.
    // oSum->lLength = lSumLength;

    ldr x0, [sp, LSUMLENGTH]
    ldr x1, [sp, OSUM]
    add x1, x1, LLENGTH
    str x0, [x1]

    // return TRUE -> epilog and ret

    mov x0, TRUE
    ldr x30, [sp]
    add sp, sp, BIGINT_STACK_BYTECOUNT
    ret

    .size   BigInt_add, (. - BigInt_add)
