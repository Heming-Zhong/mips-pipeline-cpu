`ifndef _mreg
`define _mreg

module midreg(
    input clk,
    input clear,
    input hold,
    input wire [N-1:0] in,
    output reg [N-1:0] out
);
    parameter N = 1;
    always @(posedge clk) begin
        if(clear) begin
            out <= {N{1'b0}};
        end 
        else if(hold) begin 
            out <= out;
        end
        else begin 
            out <= in;
        end 
    end

endmodule // midreg


`endif