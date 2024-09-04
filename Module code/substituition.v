`timescale 1ns/1ps
module substituition(
	input [63:0] x0,
	input [63:0] x1,
	input [63:0] x2,
	input [63:0] x3,
	input [63:0] x4,
	
	output [63:0] x0_s,
	output [63:0] x1_s,
	output [63:0] x2_s,
	output [63:0] x3_s,
	output [63:0] x4_s
);
	
	genvar i;
	generate
		for(i=0;i<64;i = i+1) begin
			sbox sb (
			{x0[i], x1[i], x2[i], x3[i], x4[i]},
			{x0_s[i], x1_s[i], x2_s[i], x3_s[i], x4_s[i]}
			);
			end
		
	endgenerate
endmodule

module sbox(
	input [4:0] in,
	output [4:0] out
);

	reg [4:0] out_buf;
	always@(in) begin
		case (in)
		5'h00	: out_buf = 5'h04;
		5'h01	: out_buf = 5'h0b;
		5'h02	: out_buf = 5'h1f;
		5'h03	: out_buf = 5'h14;
		5'h04	: out_buf = 5'h1a;
		5'h05	: out_buf = 5'h15;
		5'h06	: out_buf = 5'h09;
		5'h07	: out_buf = 5'h02;
		5'h08	: out_buf = 5'h1b;
		5'h09	: out_buf = 5'h05;
		5'h0a	: out_buf = 5'h08;
		5'h0b	: out_buf = 5'h12;
		5'h0c	: out_buf = 5'h1d;
		5'h0d	: out_buf = 5'h03;
		5'h0e	: out_buf = 5'h06;
		5'h0f	: out_buf = 5'h1c;
		5'h10	: out_buf = 5'h1e;
		5'h11	: out_buf = 5'h13;
		5'h12	: out_buf = 5'h07;
		5'h13	: out_buf = 5'h0e;
		5'h14	: out_buf = 5'h00;
		5'h15	: out_buf = 5'h0d;
		5'h16	: out_buf = 5'h11;
		5'h17	: out_buf = 5'h18;
		5'h18	: out_buf = 5'h10;
		5'h19	: out_buf = 5'h0c;
		5'h1a	: out_buf = 5'h01;
		5'h1b	: out_buf = 5'h19;
		5'h1c	: out_buf = 5'h16;
		5'h1d	: out_buf = 5'h0a;
		5'h1e	: out_buf = 5'h0f;
		5'h1f	: out_buf = 5'h17;
		endcase
	end 
	assign out = out_buf;
endmodule