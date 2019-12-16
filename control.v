`ifndef _control
`define _control

module control(
    input [5:0] opcode, funct,
    output reg [2:0] aluctr,
    output reg pcwre,alusrcA,alusrcB,dbdatasrc,dmdatasize,regdst,regwre,rd,wr,
    output reg branch_eq,branch_ne,branch_lt,jump,jr,link,extsign
);
always @( * ) begin
        pcwre = (opcode==6'b111111)?1:0;//halt or not
        case(opcode)
            6'b111111: //halt
            begin
                rd = 0;
                wr = 0;
                regwre = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
                jump = 0;
            end
            6'b000010: //j
            begin
                rd = 0;
                wr = 0;
                regwre = 0;
                jump = 1;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b000000: //R
            begin
                rd = 0;
                wr = 0;
                dbdatasrc = 0;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                case (funct)
                    6'b100000: //add
                    begin
                        aluctr = 3'b000;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 0;
                        alusrcB = 0; 
                    end
                    6'b100010: //sub
                    begin
                        aluctr = 3'b001;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 0;
                        alusrcB = 0;
                    end
                    6'b100100: //and
                    begin
                        aluctr = 3'b100;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 0;
                        alusrcB = 0;
                    end
                    6'b100101: //or
                    begin
                        aluctr = 3'b011;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 0;
                        alusrcB = 0;
                    end
                    6'b000000: //sll
                    begin
                        aluctr = 3'b010;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 1;
                        alusrcB = 0;
                    end 
                    6'b101010: //slt
                    begin
                        aluctr = 3'b110;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 0;
                        alusrcB = 0;
                    end
                    6'b001011: //movn
                    begin
                        aluctr = 3'b111;
                        regdst = 1;
                        regwre = 1;
                        alusrcA = 0;
                        alusrcB = 0;
                    end
                    6'b001000: //jr
                    begin
                        regwre = 0;
                        alusrcA = 0;
                        alusrcB = 0;
                        jr = 1;
                    end
                endcase
            end
            6'b100101: //lhu
            begin
                aluctr = 3'b000;
                rd = 1;
                wr = 0;
                regdst = 0;
                regwre = 1;
                dbdatasrc = 1;
                dmdatasize = 1;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b100011: //lw
            begin
                aluctr = 3'b000;
                rd = 1;
                wr = 0;
                dbdatasrc = 1;
                dmdatasize = 0;
                regdst = 0;
                regwre = 1;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b101011: //sw
            begin
                aluctr = 3'b000;
                wr = 1;
                rd = 0;
                regwre = 0;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b000100: //beq
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b001;
                regwre = 0;
                alusrcA = 0;
                alusrcB = 0;
                extsign = 1;
                jump = 0;
                branch_eq = 1;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b000101: //bne
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b001;
                regwre = 0;
                alusrcA = 0;
                alusrcB = 0;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 1;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b000001: //bltz
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b001;
                regwre = 0;
                alusrcA = 0;
                alusrcB = 0;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 1;
                link = 0;
                jr = 0;
            end
            6'b001000: //addi
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b000;
                dbdatasrc = 0;
                regdst = 0;
                regwre = 1;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b001001: //addiu
            begin
                aluctr = 3'b101;
                regdst = 0;
                regwre = 1;
                rd = 0;
                wr = 0;
                dbdatasrc = 0;
                alusrcA = 0;
                alusrcB = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
                extsign = 1;
            end
            6'b001100: //andi
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b100;
                dbdatasrc = 0;
                regdst = 0;
                regwre = 1;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 0;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b001101: //ori
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b011;
                dbdatasrc = 0;
                regdst = 0;
                regwre = 1;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 0;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b001010: //slti
            begin
                rd = 0;
                wr = 0;
                aluctr = 3'b110;
                dbdatasrc = 0;
                regdst = 0;
                regwre = 1;
                alusrcA = 0;
                alusrcB = 1;
                extsign = 1;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 0;
                jr = 0;
            end
            6'b000011: //jal
            begin 
                regwre = 0;
                rd = 0;
                wr = 0;
                jump = 0;
                branch_eq = 0;
                branch_ne = 0;
                branch_lt = 0;
                link = 1;
                jr = 0;
            end
        endcase
    end
endmodule // control

`endif