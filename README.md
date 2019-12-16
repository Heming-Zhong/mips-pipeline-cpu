# mips-pipeline-cpu

## Instructions
This is project belongs to a task of my cs courses.

At first, I want to say the basic idea of this project design comes from the github project as follows:

jmahler/mips-cpu: https://github.com/jmahler/mips-cpu

with the basis of jmahler's project, I implemented a mips pipeline cpu with more functions and more supported instructions.

(Although I think it would have been better for me and jmahler to create more module rather than smashing the top design file with hundreds of lines of codes...)

## Functions (update from time to time)

supported mips instructions:
1. addiu $rt, $rs, imme: unsigned addition immediate number
2. addi $rt, $rs, imme: addition with immediate number
3. add $rd, $rs, $rt: normal addition
4. sub $rd, $rs, $rt: normal subtraction
5. andi $rt, $rs, imme: bit operation and with immediate number
6. ori $rt, $rs, imme: bit operation or with immediate number
7. and $rd, $rs, $rt: normal bit operation and
8. or $rd, $rs, $rt: normal bit operation or
9. sll $rd, $rt, sa: shift left logical 
10. slti $rt, $rs, imme: set less than with immediate number
11. slt $rd, $rs, $rt: set less than
12. sw $rt, imme($rs): store word to main memory
13. lw $rt, imme($rs): load word from main memory to register group
14. lhu $rt, imme($rs): load half word from main memory to register group, with higher 16 bits filled with zero 
15. movn $rd, $rs, $rt: if rt value is not zero, move the value of rs to rd, else do nothing
16. beq $rt, $rs, imme: if rt equals to rs then branch 
17. bne $rt, $rs, imme: if rt not equals to rs then branch
18. bltz $rs, imme: if the rs value is less than zero, then branch
19. j addr: jump to addr
20. jal addr: jump to addr and set register $31 with current pc + 4
21. jr $rs: jump to the address referred by the value of rs
22. halt: as its name, an instruction stop the cpu from normally executing.
