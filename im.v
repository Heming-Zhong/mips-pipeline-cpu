`ifndef im
`define im

module im(
	input readen,
	input [31:0] pc,
	output wire [31:0] ir
);
	parameter IM_DATA = "inscode.txt";
	reg [7:0] mem[0:1024];
	initial begin
		$readmemb(IM_DATA,mem);
	end
	
	assign ir[31:24] = (readen)?8'b11111100:mem[pc];
	assign ir[23:16] = (readen)?8'b0:mem[pc+1];
	assign ir[15:8] = (readen)?8'b0:mem[pc+2];
	assign ir[7:0] = (readen)?8'b0:mem[pc+3];
	
endmodule

`endif