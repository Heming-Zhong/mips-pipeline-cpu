`ifndef im
`define im

module im(
	input [31:0] pc,
	output wire [31:0] ir
);
	parameter IM_DATA = "inscode.txt";
	reg [7:0] mem[0:1024];
	initial begin
		$readmemb(IM_DATA,mem);
	end
	
	assign ir[31:24] = mem[pc];
	assign ir[23:16] = mem[pc+1];
	assign ir[15:8] = mem[pc+2];
	assign ir[7:0] = mem[pc+3];
	
endmodule

`endif