`ifndef _dm
`define _dm

module dm(
	input clk,
	input [31:0] addr,
	input rd,wr,
	input length,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [7:0] mem[0:127];
	//write
	always @(posedge clk) begin
		if(wr) begin
			mem[addr] = wdata[31:24];
			mem[addr+1] = wdata[23:16];
			mem[addr+2] = wdata[15:8];
			mem[addr+3] = wdata[7:0];
		end
	end
	
	//read
	always @( * ) begin 
		if(rd) rdata = (length)? {{16{1'b0}},mem[addr],mem[addr+1]}:{mem[addr],mem[addr+1],mem[addr+2],mem[addr+3]};
	end

endmodule

`endif