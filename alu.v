`ifndef _alu
`define _alu

module alu(
	input [2:0] aluctr,
	input [31:0] a, b,
	output reg [31:0] res,
	output wire zero, 
	output reg wrctr
);
	assign zero = (res==0)?1:0;
	always @( * ) begin
		//default
		wrctr = 1;
		case(aluctr)
		3'b000: begin //signed addition
			res <= a + b;
			if(a[31]==0&&b[31]==0&&res[31]==1) wrctr = 0;
			else if(a[31]==1&&b[31]==1&&res[31]==0) wrctr = 0;
		end
		3'b001: begin
			res <= a - b;
			if(a[31]==0&&b[31]==0&&res[31]==1) wrctr = 0;
			else if(a[31]==1&&b[31]==1&&res[31]==0) wrctr = 0;
		end
		3'b010: begin
			res <= b << a;
		end
		3'b011: begin
			res <= a | b;
		end
		3'b100: begin
			res <= a & b;
		end
		3'b101: begin//unsigned addition (only for addiu)
			res <= a + b;
		end
		3'b110: begin//slt with sign
			res <= (((a<b)&&(a[31]==b[31]))||((a[31]==1&&b[31]==0)))?1:0;
		end
		3'b111: begin//movn
			res <= a;
			if(b==0) wrctr = 0;
		end
		endcase
	end

endmodule
`endif