`ifndef _reg
`define _reg

module register(
	input clk,
	input regwre,
	input wrctr,
	input [4:0] writereg,
	input [4:0] rs, rt, rd,
	input link,
	input [31:0] writedata,
	input [31:0] pc,
	output wire [31:0] data1, data2
);
	reg [31:0] regroup[0:31];
	reg [31:0] _data1, _data2;
	integer i;
	initial begin
		for (i = 0; i < 32; i = i+1)
			regroup[i] <= 0;
	end
	
	//write
	always @(posedge clk) begin
		if(writereg != 0 && regwre && wrctr) regroup[writereg]=writedata;
		if(link) regroup[31] = pc;
	end
	
	//read
	assign data1 = _data1;
	assign data2 = _data2;

	//read content from rs
	//=== including forwarding from WB to ID ===
	always @( * ) begin
		if(writereg == rs && regwre && wrctr) begin 
			_data1 = writedata;
		end
		else begin
			_data1 = regroup[rs];
		end
	end

	//read content from rt
	//=== including forwarding from WB to ID ===
	always @( * ) begin
		if(writereg == rt && regwre && wrctr) begin 
			_data2 = writedata;
		end
		else begin
			_data2 = regroup[rt];
		end
	end
endmodule

`endif
