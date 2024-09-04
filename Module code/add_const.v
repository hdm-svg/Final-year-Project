`timescale 1ns/1ps
module add_const(
	input [63:0] x2,
	input [4:0] ctr,
	input [4:0] rounds,
	output [63:0] out
);

	reg [63:0] out_buf;
	assign out = out_buf;
	
	//each round constance has a 15 units different 
	always @(*) begin
        if(rounds == 6)
        case(ctr)
        1: out_buf = x2 ^ 8'h96;
        2: out_buf = x2 ^ 8'h87;
        3: out_buf = x2 ^ 8'h78;
        4: out_buf = x2 ^ 8'h69;
        5: out_buf = x2 ^ 8'h5a;
        6: out_buf = x2 ^ 8'h4b;
        endcase
        if(rounds == 8)
        case(ctr)
        1: out_buf = x2 ^ 8'hb4;
        2: out_buf = x2 ^ 8'ha5;
        3: out_buf = x2 ^ 8'h96;
        4: out_buf = x2 ^ 8'h87;
        5: out_buf = x2 ^ 8'h78;
        6: out_buf = x2 ^ 8'h69;
        7: out_buf = x2 ^ 8'h5a;
        8: out_buf = x2 ^ 8'h4b;
        endcase
        if(rounds == 12)
        case(ctr)
        1: out_buf = x2 ^ 8'hf0;
        2: out_buf = x2 ^ 8'he1;
        3: out_buf = x2 ^ 8'hd2;
        4: out_buf = x2 ^ 8'hc3;
        5: out_buf = x2 ^ 8'hb4;
        6: out_buf = x2 ^ 8'ha5;
        7: out_buf = x2 ^ 8'h96;
        8: out_buf = x2 ^ 8'h87;
        9: out_buf = x2 ^ 8'h78;
        10: out_buf = x2 ^ 8'h69;
        11: out_buf = x2 ^ 8'h5a;
        12: out_buf = x2 ^ 8'h4b;
        endcase

//		if(rounds == 6)
//			out_buf = x2 ^ (8'h96 - (ctr-1) *15);
//		else if (rounds == 8)
//			out_buf = x2 ^ (8'hb4 - (ctr-1) *15);
//		else 
//			out_buf = x2 ^ (8'hf0 - (ctr-1) *15);
	end
endmodule