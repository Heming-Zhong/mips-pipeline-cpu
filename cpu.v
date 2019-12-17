/*
 * mips five stages pipeline cpu
 *
 * the regulation of wire-naming
 * appending the current stage number such as:
 * 
 * wire data_s1;
 * wire data_s2;
 */

`include "control.v"
`include "mid-reg.v"
`include "register.v"
`include "alu.v"
`include "im.v"
`include "dm.v"

module cpu(
    //input wire clk
);
    reg clk;

    parameter INSPATH = "./inscode.txt";
    reg stall_s1_s2;
    wire [4:0] writereg_s5;
    wire [31:0] regwr_data_s5;
    wire regwre_s5;
    wire jal_s5;
    wire wrctr_s5;
    wire [31:0] pc4_s5;
    wire pcwre_s5;
    
    //flush control
    //static branch prediction 
    //always stall when branch occurs
    reg flush_s1, flush_s2, flush_s3;
    always @( * ) begin
        flush_s1 <= 0;
        flush_s2 <= 0;
        flush_s3 <= 0;
        if(pcsrc == 2'b01 || pcsrc == 2'b10 || pcsrc == 2'b11 || pcwre_s4 == 1) begin
            flush_s1 <= 1;
            flush_s2 <= 1;
            flush_s3 <= 1;
        end  
    end


    //stage one -- IF
    reg [31:0] pc;
    initial begin 
        clk <= 1;
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0,cpu);
        pc <= 0;
        #1500
        $finish;
    end

    always #5 clk = ~clk;

    wire [31:0] pc4;
    assign pc4 = pc + 4;
    always @(posedge clk) begin
        if(pcwre_s5) begin
            pc <= pc;
        end
        else if(stall_s1_s2) begin
            pc <= pc;
        end
        else begin
            case(pcsrc)
                2'b00: //pc + 4
                begin
                    pc <= pc4;
                end 
                2'b01: // branch
                begin
                    pc <= branchaddr_s4;
                end
                2'b10: // j or jal
                begin
                    pc <= jumpaddr_s4;
                end
                2'b11: // jr
                begin
                    pc <= jraddr_s4;
                end
                default: pc<=pc4;
            endcase
        end
    end

    // - pass the pc4 to next stage
    wire [31:0] pc4_s2;
    midreg #(.N(32)) midreg_pc4_s1( .clk(clk),
                                    .clear(flush_s1),
                                    .hold(stall_s1_s2),
                                    .in(pc4),
                                    .out(pc4_s2));
    //instruction memory
    wire [31:0] ir,ir_s2;
    im im_1(
        .readen(pcwre_s5),
		.pc(pc),
		.ir(ir)
    );
    midreg #(.N(32)) midreg_im_s1(.clk(clk),
                                  .clear(flush_s1),
                                  .hold(stall_s1_s2),
                                  .in(ir),
                                  .out(ir_s2));

    //== == == == == 
    //stage two -- ID
    //===============
    // decode instruction
    wire [5:0] opcode, funct;
    wire [4:0] rs, rt, rd, sa;
    wire [15:0] imme;
    wire [25:0] rep;
    wire [31:0] seimme; // sign extended immediate
    wire [31:0] zeimme; // zero extended immediate
    wire [31:0] jumpaddr_s2;
    wire [31:0] branchaddr_s2;
    wire [31:0] jraddr_s2;

    assign opcode = ir_s2[31:26];
    assign funct = ir_s2[5:0];
    assign rs = ir_s2[25:21];
    assign rt = ir_s2[20:16];
    assign rd = ir_s2[15:11];
    assign imme = ir_s2[15:0];
    assign sa = ir_s2[10:6];
    assign rep = ir_s2[25:0];
    assign seimme = {{16{imme[15]}},imme};
    assign zeimme = {{16{1'b0}},imme};
    assign jumpaddr_s2 = {pc4_s2[31:28],rep,2'b00};
    assign branchaddr_s2 = pc4_s2 + {seimme[29:0],2'b00};


    //register group
    wire [31:0] data1,data2;// rs data and rt data
    register regm(
        .clk(clk),
        .regwre(regwre_s5),
        .wrctr(wrctr_s5),
        .writereg(writereg_s5),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .data1(data1),
        .data2(data2),
        .link(jal_s5),
        .pc(pc4_s5),
        .writedata(regwr_data_s5)
    );

    assign jraddr_s2 = data1;

    //pass rs rd rt to stage 3
    wire [4:0] rs_s3,rt_s3,rd_s3;
    midreg #(.N(5))midreg_rs_s2(
        .clk(clk),
        .clear(1'b0),
        .hold(stall_s1_s2),
        .in(rs),
        .out(rs_s3)
    );
    midreg #(.N(10))midreg_rt_rd_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(stall_s1_s2),
        .in({rt,rd}),
        .out({rt_s3,rd_s3})
    );

    //pass shamt to stage 3
    wire [4:0] sa_s3;
    midreg #(.N(5))midreg_sa_s2(
        .clk(clk),
        .clear(1'b0),
        .hold(stall_s1_s2),
        .in(sa),
        .out(sa_s3)
    );

    //pass register data to stage 3
    wire [31:0] data1_s3,data2_s3;
    midreg #(.N(64))midreg_regdata_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(stall_s1_s2),
        .in({data1,data2}),
        .out({data1_s3,data2_s3})
    );

    //pass imme
    wire [31:0] seimme_s3,zeimme_s3;
    midreg #(.N(32))midreg_seimme_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(stall_s1_s2),
        .in(seimme),
        .out(seimme_s3)
    );
    
    midreg #(.N(32))midreg_zeimme_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(stall_s1_s2),
        .in(zeimme),
        .out(zeimme_s3)
    );
    
    //pass pc + 4
    wire [31:0] pc4_s3;
    midreg #(.N(32))midreg_pc4_s2(
        .clk(clk),
        .clear(1'b0),
        .hold(stall_s1_s2),
        .in(pc4_s2),
        .out(pc4_s3)
    );

    // control signals 
    wire regdst,regwre,Rd,Wr,dbdatasrc,alusrcA,alusrcB,extsign;
    wire pcwre,dmdatasize;
    wire [2:0] aluctr;
    wire jump_s2,branch_eq_s2,branch_ne_s2,branch_lt_s2,jr_s2,jal_s2;
    control ctr1(.opcode(opcode),
                 .funct(funct),
                 .pcwre(pcwre),
                 .aluctr(aluctr),
                 .regdst(regdst),
                 .regwre(regwre),
                 .rd(Rd),
                 .wr(Wr),
                 .dbdatasrc(dbdatasrc),
                 .dmdatasize(dmdatasize),
                 .alusrcA(alusrcA),
                 .alusrcB(alusrcB),
                 .jump(jump_s2),
                 .branch_eq(branch_eq_s2),
                 .branch_ne(branch_ne_s2),
                 .branch_lt(branch_lt_s2),
                 .link(jal_s2),
                 .jr(jr_s2),
                 .extsign(extsign));
    //pass control signals 
    wire regdst_s3;
    wire regwre_s3;
    wire Rd_s3;
    wire Wr_s3;
    wire dbdatasrc_s3;
    wire alusrcA_s3;
    wire alusrcB_s3;
    wire [2:0] aluctr_s3;
    wire pcwre_s3;
    wire dmdatasize_s3;
	wire extsign_s3;
    midreg #(.N(12)) midreg_ctr_s2(
        .clk(clk),
        .clear(stall_s1_s2),
        .hold(1'b0),
        .in({dmdatasize,regdst,regwre,Rd,Wr,dbdatasrc,alusrcA,alusrcB,aluctr,extsign}),
        .out({dmdatasize_s3,regdst_s3,regwre_s3,Rd_s3,Wr_s3,dbdatasrc_s3,alusrcA_s3,alusrcB_s3,aluctr_s3,extsign_s3})  
    );
    midreg #(.N(1)) midreg_pcwre_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(stall_s1_s2),
        .in(pcwre),
        .out(pcwre_s3)
    );

    //pass branch signals 
    wire jump_s3;
    wire branch_eq_s3;
    wire branch_ne_s3;
    wire branch_lt_s3;
    wire jal_s3;
    wire jr_s3;
    midreg #(.N(6)) midreg_jtype_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(1'b0),
        .in({jump_s2,branch_eq_s2,branch_ne_s2,branch_lt_s2,jal_s2,jr_s2}),
        .out({jump_s3,branch_eq_s3,branch_ne_s3,branch_lt_s3,jal_s3,jr_s3})
    );
    //pass branch address
    wire [31:0] branchaddr_s3;
    wire [31:0] jumpaddr_s3;
    wire [31:0] jraddr_s3;
    midreg #(.N(96))midreg_jaddr_s2(
        .clk(clk),
        .clear(flush_s2),
        .hold(1'b0),
        .in({branchaddr_s2,jumpaddr_s2,jraddr_s2}),
        .out({branchaddr_s3,jumpaddr_s3,jraddr_s3})
    );

    //stage three -- EXE

    // pass through some control signals to stage 4 -- not gotta be used in stage 3
    wire dmdatasize_s4;
    wire regdst_s4;
    wire regwre_s4;
    wire dbdatasrc_s4;
    wire pcwre_s4;
    wire Rd_s4;
    wire Wr_s4;
    midreg #(.N(1))midreg_pcwre_s3(
        .clk(clk),
        .clear(1'b0),
        .hold(flush_s3),
        .in(pcwre_s3),
        .out(pcwre_s4)
    );
    midreg #(.N(6))midreg_somectr_s3(
        .clk(clk),
        .clear(flush_s3),
        .hold(1'b0),
        .in({dmdatasize_s3,regwre_s3,regdst_s3,dbdatasrc_s3,Rd_s3,Wr_s3}),
        .out({dmdatasize_s4,regwre_s4,regdst_s4,dbdatasrc_s4,Rd_s4,Wr_s4})
    );

    wire [31:0] alures;
    wire [31:0] aluin1_s3;
    wire [31:0] aluin2_s3;
    reg [31:0] fwdata1_s3;
    //get operand A with consideration of forwarding
    always @( * ) begin
        case (forward_a)
            2'd1: fwdata1_s3 = alures_s4; 
            2'd2: fwdata1_s3 = regwr_data_s5; 
        default: fwdata1_s3 = data1_s3; // no forwarding
        endcase
    end
    reg [31:0] fwdata2_s3;
    always @( * ) begin
        case (forward_b)
            2'd1: fwdata2_s3 = alures_s4;
            2'd2: fwdata2_s3 = regwr_data_s5;
            default: fwdata2_s3 = data2_s3;
        endcase
    end
    wire [31:0] immm;
    assign immm = (extsign_s3)?seimme_s3:zeimme_s3;
    assign aluin2_s3 = (alusrcB_s3)?immm:fwdata2_s3;
    assign aluin1_s3 = (alusrcA_s3)?sa_s3:fwdata1_s3;
    wire zero_s3;
    wire wrctr_s3;
    alu alu1(
        .aluctr(aluctr_s3),
        .a(aluin1_s3),
        .b(aluin2_s3),
        .res(alures),
        .zero(zero_s3),
        .wrctr(wrctr_s3)
    );
    
    //pass overflow & movn conditional signal to stage 4
    wire wrctr_s4;
    midreg #(.N(1))midreg_wrctr_s3(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in(wrctr_s3),
        .out(wrctr_s4)
    );

    //pass the alu result and zero to stage 4
    wire [31:0] alures_s4;
    wire zero_s4;
    midreg #(.N(1))midreg_zero_s3(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in(zero_s3),
        .out(zero_s4)
    );
    midreg #(.N(32))midreg_alures_s3(
        .clk(clk),
        .clear(flush_s3),
        .hold(1'b0),
        .in(alures),
        .out(alures_s4)
    );

    //pass "rt" data to stage 4
    wire [31:0] data2_s4;
    midreg #(.N(32))midreg_regdata_s4(
        .clk(clk),
        .clear(flush_s3),
        .hold(1'b0),
        .in(fwdata2_s3),
        .out(data2_s4)
    );

    //pass branch address to stage 4
    wire [31:0] branchaddr_s4;
    wire [31:0] jumpaddr_s4;
    wire [31:0] jraddr_s4;//equal to fwdata1_s3 in case of forwarding
    midreg #(.N(96))midreg_jaddr_s3(
        .clk(clk),
        .clear(flush_s3),
        .hold(1'b0),
        .in({branchaddr_s3,jumpaddr_s3,fwdata1_s3}),
        .out({branchaddr_s4,jumpaddr_s4,jraddr_s4})
    );

    //pass branch signals to stage 4
    wire branch_eq_s4;
    wire branch_ne_s4;
    wire branch_lt_s4;
    wire jump_s4;
    wire jal_s4;
    wire jr_s4;
    midreg #(.N(6))midreg_jtype_s3(
        .clk(clk),
        .clear(flush_s3),
        .hold(1'b0),
        .in({branch_eq_s3,branch_ne_s3,branch_lt_s3,jump_s3,jal_s3,jr_s3}),
        .out({branch_eq_s4,branch_ne_s4,branch_lt_s4,jump_s4,jal_s4,jr_s4})
    );

    // write register(；´Д`A
    wire [4:0] writereg, writereg_s4;
    assign writereg = (regdst_s3)?rd_s3:rt_s3;
    midreg #(.N(5))midreg_wreg(
        .clk(clk),
        .clear(flush_s3),
        .hold(1'b0),
        .in(writereg),
        .out(writereg_s4)
    );
    
    //pass pc4 to stage 4
    wire [31:0] pc4_s4;
    midreg #(.N(32)) midreg_pc4_s3(
    	.clk(clk),
    	.clear(flush_s3),
    	.hold(1'b0),
    	.in(pc4_s3),
    	.out(pc4_s4)
    );
    
    //stage four -- MEM
    
    //pass reg control signals to stage 5
    wire dbdatasrc_s5;
    midreg #(.N(3))midreg_write_s4(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in({regwre_s4,dbdatasrc_s4,jal_s4}),
        .out({regwre_s5,dbdatasrc_s5,jal_s5})
    );

    // data memory
    wire [31:0] readata;
    dm dm1(
        .clk(clk),
        .addr(alures_s4),
        .rd(Rd_s4),
        .wr(Wr_s4),
        .length(dmdatasize_s4),
        .wdata(data2_s4),
        .rdata(readata)
    );

    //pass overflow & movn conditional signal to stage 5
    midreg #(.N(1))midreg_wrctr_s4(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in(wrctr_s4),
        .out(wrctr_s5)
    );

    // pass read data to stage 5
    wire [31:0] readata_s5;
    midreg #(.N(32))midreg_dmdata_s4(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in(readata),
        .out(readata_s5)
    );

    //pass write register to stage 5
    midreg #(.N(5))midreg_wreg_s4(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in(writereg_s4),
        .out(writereg_s5)
    );

    //pass alures to stage 5
    wire [31:0] alures_s5;
    midreg #(.N(32))midreg_alures_s4(
        .clk(clk),
        .clear(1'b0),
        .hold(1'b0),
        .in(alures_s4),
        .out(alures_s5)
    );

    //branch and jump
    reg [1:0] pcsrc;
    always @( * ) begin 
        if(branch_eq_s4) begin //beq ins
            case(zero_s4)
                0: pcsrc <= 2'b00;
                1: pcsrc <= 2'b01;
                default: pcsrc <= 2'b00;
            endcase
        end
        else if(branch_ne_s4) begin //bne ins
            case(zero_s4)
                0: pcsrc <= 2'b01;
                1: pcsrc <= 2'b00;
                default: pcsrc <= 2'b00;
            endcase
        end
        else if(branch_lt_s4) begin //bltz ins
            case(alures_s4[31])
                0: pcsrc <= 2'b00;
                1: pcsrc <= 2'b01;
                default: pcsrc <= 2'b00;
            endcase
        end
        else if(jal_s4 || jump_s4) begin //j or jal ins
            pcsrc <= 2'b10;
        end
        else if(jr_s4) begin 
            pcsrc <= 2'b11;
        end
        else begin //normal ins
            pcsrc <= 2'b00;
        end
    end

	//pass pc4 to stage 5
	midreg #(.N(32))midreg_pc4_s4(
		.clk(clk),
		.clear(1'b0),
		.hold(1'b0),
		.in(pc4_s4),
		.out(pc4_s5)
	);

    //pass pcwre to stage 5 -- judging halt or not
    midreg #(.N(1))midreg_pcwre_s4(
        .clk(clk),
        .clear(1'b0),
        .hold(pcwre_s5),
        .in(pcwre_s4),
        .out(pcwre_s5)
    );

    //stage five -- WB

    assign regwr_data_s5 = (dbdatasrc_s5)?readata_s5:alures_s5;


    //=== forwarding ===
    //2'd1: MEM to EXE
    //2'd2: WB to EXE
    //=== forwarding ===
    reg [1:0] forward_a,forward_b;
    always @( * ) begin 
        if((regwre_s4 == 1 && wrctr_s4 == 1) && (writereg_s4 == rs_s3) && (writereg_s4 != 0)) begin
            forward_a <= 2'd1;
        end
        else if((regwre_s5 == 1 && wrctr_s5 == 1) && (writereg_s5 == rs_s3) && (writereg_s5 != 0)) begin
            forward_a <= 2'd2;
        end
        else forward_a <= 2'd0;

        if((regwre_s4 == 1 && wrctr_s4 == 1) && (writereg_s4 == rt_s3) && (writereg_s4 != 0)) begin
            forward_b <= 2'd1;
        end    
        else if((regwre_s5 == 1 && wrctr_s5 == 1) && (writereg_s5 == rt_s3) && (writereg_s5 != 0)) begin
            forward_b <= 2'd2;
        end
        else forward_b <= 2'd0;
    end


    //
    always @( * ) begin
        if(pcwre_s5 == 1) begin
            pc = 32'h000000c8;
        end
    end

    //=== load-use data hazard ===
    always @( * ) begin 
        if(Rd_s3 == 1 && (rt == rt_s3 || rs == rt_s3)) begin 
            stall_s1_s2 <= 1; // a stall
        end
        else stall_s1_s2 <= 0; // no stall
    end

endmodule // cpu
