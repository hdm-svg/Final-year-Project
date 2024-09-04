`timescale 1ns/1ps
module decryption #(
	parameter KEY_l = 128,
	parameter RATE = 64,
	parameter a = 12,
	parameter b = 6,
	parameter A_l = 40,
	parameter Ct_l = 40
)(
	input clk,
	input rst,
	input [KEY_l-1:0] key,
	input [127:0] nonce,
	input [A_l-1:0] associated,
	input [Ct_l-1:0] ciphertext,
//	input [127:0] tag_in,
	input dec_start,
	
	output [Ct_l-1:0] dec_plaintext,
	output [127:0] tag_out,
	output dec_ready
);

	localparam c = 320-RATE;
//	if((A_l+1)%RATE==0)
//		localparam pad_A =0;
//	else
//		localparam pad_A = (RATE-(A_l-1)%RATE);
	localparam pad_A = ((A_l+1)%RATE == 0)? 0:RATE-((A_l-1)%RATE);
	localparam pad_A_length = A_l+1+pad_A;
	localparam s = pad_A_length/RATE;
	
//	if((Ct_l+1)%RATE==0)
//		localparam Ct_l = 0;
//	else
//		localparam Ct_l = RATE - (Ct_l+1)%RATE);
	localparam pad_Ct = ((Ct_l+1)%RATE == 0)? 0: RATE-((Ct_l+1)%RATE);
	localparam pad_Ct_length = Ct_l+1+pad_Ct;
	localparam t = pad_Ct_length/RATE;
	
	//buffers
	reg [4:0] rounds;
	reg [127:0] Tag;
	reg [127:0] Tag_reg;
	reg de_ready_reg;
	wire [31:0] IV;
	reg [319:0] S;
	wire [RATE-1:0] Sr;
	wire [c-1:0] Sc;
	reg [319:0] P_in;
	wire [319:0] P_out;
	wire prm_ready;
	reg prm_start;
	wire [pad_A_length-1:0] Asc_data;
	wire [pad_Ct_length-1:0] Cipher;
	reg [pad_Ct_length-1:0] Plain;
	reg [pad_Ct_length-1:0] Plain_reg;
	reg [t:0] block_ctr;
	wire [4:0] ctr;
	
	
	assign IV = (KEY_l << 24) | (RATE << 16) | (a << 8) | b;
	assign {Sr,Sc} = S;
	assign dec_ready = de_ready_reg;
	assign Asc_data = {associated, 1'b1, {pad_A{1'b0}}};
	assign Cipher = {ciphertext, 1'b1, {pad_Ct{1'b0}}};
//	if(de_ready_reg == 1)
//		assign tag_out = Tag;
//	else 
//		assign tag_out = 0;
	assign tag_out = (de_ready_reg)? Tag : 0;
	if(Ct_l>0)
//		if(de_ready_reg == 1)
//			assign dec_plaintext = Plain[pad_Ct_length-1: pad_Ct_length - Ct_l];
//		else 
//			assign dec_plaintext = 0;
		assign dec_plaintext = (de_ready_reg)? Plain[pad_Ct_length-1: pad_Ct_length - Ct_l] : 0;
	else
		assign dec_plaintext = 0;

	
	localparam 
	IDLE ='d0,
	INITIALIZE ='d1,
	ASSOCIATED = 'd2,
	PROCESS_CT = 'd3,
	FINALIZE ='d4,
	DONE = 'd5;
	reg [2:0] state;
	
	//State progession
	always @(posedge clk) begin
		if(rst) begin
			state <= IDLE;
			S <=0;
			Tag <=0;
			Plain <= 0;
			block_ctr <=0;
		end
		else begin
			case(state)
			
			IDLE: begin
				S <= {IV, {(160-KEY_l){1'b0}}, key, nonce};
				if(dec_start)
					state <=INITIALIZE;
			end
			
			INITIALIZE: begin
				if(prm_ready) begin
					if(A_l !=0)
						state <= ASSOCIATED;
					else if (A_l == 0 && Ct_l != 0)
						state <= PROCESS_CT;
					else
						state <=FINALIZE;
					S <= P_out ^ {{(320-KEY_l){1'b0}}, key};
				end
			end
			
			ASSOCIATED: begin
				if(prm_ready && block_ctr == s-1) begin
					if(Ct_l !=0)
						state <= PROCESS_CT;
					else
						state <= FINALIZE;
					S <= P_out ^ ({{319{1'b0}}, 1'b1});
				end
				else if (prm_ready && block_ctr !=s)
					S <= P_out;
				if (prm_ready && block_ctr == s-1)
					block_ctr <= 0;
				else if(prm_ready && block_ctr !=s)
					block_ctr <= block_ctr+1;
			end
			
			PROCESS_CT: begin
				if(block_ctr == t-1) begin 
					state <=FINALIZE;
					if(Ct_l > 0 && Ct_l%RATE != 0)
						S <= {(Sr ^ {Plain_reg[(RATE-1)-: Ct_l%RATE], 1'b1, {(RATE-1-Ct_l%RATE){1'b0}}}), Sc};
					else if(Ct_l > 0 && Ct_l%RATE == 0)
						S <= {(Sr ^ {1'b0, 1'b1, {(RATE-1-Ct_l%RATE){1'b0}}}), Sc};
					Plain <= Plain + Plain_reg;
				end
				else if (prm_ready && block_ctr !=t) begin
					S <= P_out;
					Plain <= Plain + Plain_reg;
				end
				if(prm_ready && block_ctr == t-1)
					block_ctr <= 0;
				else if (prm_ready && block_ctr !=t)
					block_ctr <= block_ctr +1;
			end
			
			FINALIZE: begin
				if(prm_ready) begin
					S <= P_out;
					state <= DONE;
					Tag <= Tag_reg;
				end
			end
			
			DONE: begin
				if(dec_start)
					state <= IDLE;
			end
			
			default:
				state <= IDLE;
			endcase
		end
	end
	
	//signal update
	always @(*) begin
		Plain_reg = 0;
		Tag_reg =0;
		de_ready_reg = 0;
		case (state)
			IDLE: begin
				Plain_reg = 0;
				Tag_reg = 0;
				de_ready_reg = 0;
				prm_start = 0;
				rounds = a;
				P_in = S;
			end
			
			INITIALIZE: begin
				Plain_reg = 0;
				Tag_reg =0;
				de_ready_reg = 0;
				rounds = a;
//				if(prm_ready)
//					prm_start = 1;
//				else prm_start = 0;
				prm_start = (prm_ready)? 1'b0: 1'b1;
				P_in = S;
			end
			
			ASSOCIATED: begin
				Plain_reg = 0;
				de_ready_reg = 0;
				rounds = b;
				Tag_reg = 0;
				if(prm_ready && block_ctr == (s-1))
					prm_start =0;
				else
					prm_start =1;
				P_in = {Sr^Asc_data[pad_A_length-1-(block_ctr*RATE)-:RATE], Sc};
			end
			
			PROCESS_CT: begin
				de_ready_reg =0;
				rounds = b;
				Tag_reg =0;
				Plain_reg[pad_Ct_length-1-(block_ctr*RATE)-:RATE] = Sr^ Cipher[pad_Ct_length-1-(block_ctr*RATE)-:RATE];
				P_in = {Cipher[pad_Ct_length-1-(block_ctr*RATE)-:RATE],Sc};
				if (block_ctr == (t-1))
					prm_start =0;
				else
					prm_start =1;
			end
			
			FINALIZE: begin
				Plain_reg =0;
				rounds = a;
				P_in = S ^ ({{RATE{1'b0}},key,{(c-KEY_l){1'b0}}});
				prm_start = (prm_ready)? 1'b0: 1'b1;
				de_ready_reg = 0;
				Tag_reg = P_out ^ key;
			end
			
			DONE: begin
				Tag_reg = 0;
				Plain_reg = 0;
				rounds = a;
				P_in = 0;
				prm_start =0;
				de_ready_reg = 1;
			end
			
			default: begin
				Tag_reg =0;
				rounds = 0;
				P_in = S;
				prm_start = 0;
				de_ready_reg =0;
				Plain_reg = 0;
			end
		endcase
	end
	
	permutation p(
		.clk(clk),
		.rst(rst),
		.S(P_in),
		.out(P_out),
		.done(prm_ready),
		.ctr(ctr),
		.rounds(rounds),
		.start(prm_start)
	);
	
	round_ctr rc(
		clk,
		rst,
		prm_start,
		prm_ready,
		ctr
	);
endmodule	
//`timescale 1ns/1ps
//module round_de_ctr(
//	input clk,
//	input rst,
//	input prm_start,
//	input prm_ready,
//	output [4:0] counter
//);
//	reg [4:0] ctr;
//	always @(posedge clk) begin
//		if(rst)
//			ctr <=0;
//		else begin
//			if(prm_ready || ~prm_start)
//				ctr <=0;
//			else if (prm_start)
//				ctr<=ctr+1;
//		end
//	end
//	assign counter = ctr;
//endmodule

					