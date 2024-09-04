`timescale 1ns/1ps
module permutation(
	input clk,
	input rst,
	input [4:0] ctr,
	input [319:0] S,
	input [4:0] rounds,
	input start,
	
	output [319:0] out,
	output done
);

	//inner Reg
	reg [63:0] x0,x1,x2,x3,x4;
	wire [63:0] x0_o,x1_o,x2_o,x3_o,x4_o;
	reg Done;
	
	//Update inner reg with positive egde clock cycle.
	always @(posedge clk) begin
		if(rst)
			{x0, x1, x2, x3, x4, Done} <=0;
		else begin
			if(start) begin
				if(ctr == 0)
				//first round assign S to input register
					{x0, x1, x2, x3, x4} <= S;
				else begin
					x0 <= x0_o;
					x1 <= x1_o;
					x2 <= x2_o;
					x3 <= x3_o;
					x4 <= x4_o;
				end
			end
		end
		if(ctr == rounds) //match the amount of round needed
			Done <= 1;
		else
			Done <= 0;
		end
		
		assign done = Done;
		
		assign out = {x0, x1, x2, x3, x4};
		
		//adding constant
		wire [63:0] rc_x2;
		add_const pc(
			.x2(x2),
			.ctr(ctr),
			.out(rc_x2),
			.rounds(rounds)
		);
		
		//substituition
		wire [63:0] x0_s,x1_s,x2_s,x3_s,x4_s;
		substituition ps(
			.x0(x0),
			.x1(x1),
			.x2(rc_x2),
			.x3(x3),
			.x4(x4),
			.x0_s(x0_s),
			.x1_s(x1_s),
			.x2_s(x2_s),
			.x3_s(x3_s),
			.x4_s(x4_s)
		);  
		
		//Linear
		linear_diffuse pl(
			.x0(x0_s),
			.x1(x1_s),
			.x2(x2_s),
			.x3(x3_s),
			.x4(x4_s),
			.x0_o(x0_o),
			.x1_o(x1_o),
			.x2_o(x2_o),
			.x3_o(x3_o),
			.x4_o(x4_o)
		);
endmodule