//----------------------------------------------------------------------
// mywc.s
// Author: Roy Mazumder
//----------------------------------------------------------------------

    .section .data

lLineCount: .quad 0
lWordCount: .quad 0
lCharCount: .quad 0
iInWord: .word 0

    .section .bss
iChar: .skip 1

    .section .text

    //--------------------------------------------------------------
    // Read from standard int, count numbers of lines, words, and characthers
    // and print them out in that order to stdout
    // int main(void) returns 0
    //--------------------------------------------------------------

    // Must be a multiple of 16
    .equ    MAIN_STACK_BYTECOUNT, 16
    .equ    TRUE, 1
    .equ    FALSE, 0
    .equ    EOF, -1

    .global main

main:
    // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

mainLoop:
    // while ((iChar = getchar()) != EOF)
        adr     x9, iChar
        bl      getchar
        cmp     w0, EOF
        beq     endMainLoop
        str     w0, [x9]

    // lCharCount++;
        adr     x10, lCharCount
        ldr     x11, [x10]
        add     x11, x11, 1
        str     x11, [x10]
    
    // if (isspace(iChar)) (w0 contains iChar)

        bl      isspace
        cmp     w0, FALSE
        beq     elseBlock

    // if (iInWord)
        adr     x9, iInWord
        ldr     w10, [x9]
        cmp     w10, FALSE
        beq     afterConditions

        // lWordCount++
        adr     x11, lWordCount
        ldr     x12, [x11]    
        add     x12, x12, 1
        str     x12, [x11]

        // iInWord = FALSE

        mov     w10, FALSE
        str     w10, [x9]

elseBlock:

        // if (!iInWord)

        adr     x9, iInWord
        ldr     w10, [x9]
        cmp     w10, TRUE
        beq     afterConditions

        //    iInWord = TRUE;
        mov     w10, TRUE
        str     w10, [x9]

afterConditions:
        // if (iChar == '\n')
        adr     x9, iChar
        ldr     w10, [x9]
        cmp     w10, '\n'
        bne     mainLoopBack
        // lLineCount++;

        adr     x9, lLineCount
        ldr     x10, [x9]
        add     x10, x10, 1
        str     x10, [x9]

mainLoopBack:
        b       mainLoop

endMainLoop:
    //  if (iInWord) lWordCount++;

        adr     x9, iInWord
        ldr     w10, [x9]
        cmp     w10, FALSE
        beq     epilog

        adr     x9, lWordCount
        ldr     x10, [x9]    
        add     x10, x10, 1
        str     x10, [x9]


epilog:
    // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);

        adr     x9, lLineCount
        adr     x10, lWordCount
        adr     x11, lCharCount
        ldr     x0, [x9]
        ldr     x1, [x10]
        ldr     x2, [x11]
        bl      printf



// Epilog and return 0
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret
        .size   main, (. - main)