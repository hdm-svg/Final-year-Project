`timescale 1ns/1ps
module round_ctr(
	input clk,
	input rst,
	input permutation_s,
	input permutation_r,
	output [4:0] counter
);
	reg [4:0] ctr;
	always @(posedge clk) begin
		if(rst)
			ctr <=0;
		else begin
			if(permutation_r || ~permutation_s)
				ctr <=0;
			else if (permutation_s)
				ctr<=ctr+1;
		end
	end
	assign counter = ctr;
endmodule
