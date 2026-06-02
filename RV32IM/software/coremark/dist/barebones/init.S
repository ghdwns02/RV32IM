.section    .start1
.global     _start1

_start1:
    li      sp, 0x1000fff0
    #jal     main

    // newlib _start expects argc, argv on the stack. Leave stack 16-byte aligned.
    addi sp, sp, -16
    li a0, 1
    sw a0, (sp)
    la a0, progname
    sw a0, 4(sp)

    jal     _start

progname:
	.asciz "rv32im-testbench"
