`timescale 1ns/1ps
module encryption #(
	parameter KEY_l = 128,	// key
	parameter RATE = 64,	//rate
	parameter a = 12,	//initial round
	parameter b = 6, 	//inner round
	parameter A_l = 40,	//associated data length
	parameter Pt_l = 40 	//plaintext length
	)(
	input clk,
	input rst,
	input [KEY_l-1:0] key,
	input [127:0] nonce,
	input [A_l-1:0] associated,
	input [Pt_l-1:0] plaintext,
	input en_start,
	
	output [Pt_l-1:0] ciphertext,
	output [127:0] tag,
	output en_ready
	);
	
	localparam c = 320 -RATE;
	/*check length of associated data, pad_A length(number of 0s)
	if the length with append 1 is divisable by RATE --> no 0s needed
	otherwise calculate the 0s needed for the append process (RATE-(A_l-1)mod RATE)*/
//	if ((A_l+1)%RATE == 0)
//		pad_A = 0;
//	else
//		pad_A = RATE - ((A_l-1)%RATE);
	localparam pad_A = ((A_l+1)%RATE == 0)? 0:RATE-((A_l-1)%RATE);
	localparam pad_A_length = A_l+1+pad_A;
	localparam s = pad_A_length/RATE; //numbers of RATE-block associated data 
	
	//same thing as associated data here with the pad for plaintext
//	if ((A_l+1)%RATE ==0)
//		pad_Pt = 0;
//	else
//		pad_Pt = RATE - ((Pt_l+1)%RATE);
	localparam pad_Pt = ((Pt_l+1)%RATE == 0)? 0: RATE-((Pt_l+1)%RATE);
	localparam pad_Pt_length = Pt_l+1+pad_Pt;
	localparam t = pad_Pt_length/RATE; //numbers of RATE-block plaintext
	
	//buffers
	reg [4:0] rounds;
	reg [127:0] Tag;
	reg [127:0] Tag_reg;
	reg en_ready_reg;
	wire [31:0] IV;
	reg [319:0] S;
	wire [RATE-1:0] Sr;
	wire [c-1:0] Sc;
	reg [319:0] P_in;
	wire [319:0] P_out;
	wire prm_ready;
	reg prm_start;
	wire [pad_A_length-1:0] Asc_data;
	wire [pad_Pt_length-1:0] Plain;
	reg [pad_Pt_length-1:0] Cipher;
	reg [pad_Pt_length-1:0] Cipher_reg;
	reg [t:0] block_ctr;
	wire [4:0] ctr;
	
	assign IV = (KEY_l << 24) | (RATE << 16) | (a << 8) | b;
	//seperate into two for step that need add data - part of ascon algorithym.
	assign {Sr,Sc} = S;
	assign en_ready = en_ready_reg;
	assign Asc_data = {associated, 1'b1, {pad_A{1'b0}}};//after padded
	assign Plain = {plaintext, 1'b1, {pad_Pt{1'b0}}};//after padded
	assign tag = (en_ready_reg)? Tag : 0;//done encryption pull out tag
	if(Pt_l>0)
		assign ciphertext = (en_ready_reg)? Cipher[pad_Pt_length-1: pad_Pt_length - Pt_l] : 0;//same as Tag
	else
		assign ciphertext = 0;

	
	// FSM States
	localparam 
	IDLE ='d0,
	INITIALIZE ='d1,
	ASSOCIATED = 'd2,
	PROCESS_PT = 'd3,
	FINALIZE ='d4,
	DONE = 'd5;
	reg [2:0] state;
	
	//State progression
	always @(posedge clk) begin
		if(rst) begin
			state <= IDLE;
			S <= 0;
			Tag <= 0;
			Cipher <= 0;
			block_ctr <= 0;
		end
		else begin
			case(state)
			
			IDLE: begin
				S <={IV, {(160-KEY_l){1'b0}},key, nonce}; //add 0s in for the IV 
				if(en_start)
					state <= INITIALIZE;
			end
			
			INITIALIZE: begin
				if (prm_ready) begin
					if(A_l!=0)
						state <= ASSOCIATED;
					else if(A_l == 0 && Pt_l !=0)
						state <= PROCESS_PT;
					else
						state <= FINALIZE;
					S<= P_out ^ {{(320-KEY_l){1'b0}}, key};
				end 
			end
			
			ASSOCIATED: begin
				if(prm_ready && block_ctr == s-1) begin
					if(Pt_l!=0)
						state <= PROCESS_PT;
					else
						state <= FINALIZE;
					S <= P_out ^ ({{319{1'b0}},1'b1});
				end
				else if (prm_ready && block_ctr !=s)
					S <= P_out;
				if (prm_ready && block_ctr == s-1)
					block_ctr <= 0;
				else if(prm_ready && block_ctr !=s)
					block_ctr <= block_ctr+1;
			end 
			
			PROCESS_PT: begin
				if (block_ctr == t-1)begin
					state <= FINALIZE;
					S <= {Cipher_reg[RATE-1:0], Sc};
					Cipher <= Cipher + Cipher_reg;
				end
				else if (prm_ready && block_ctr !=t) begin
					S <= P_out;
					Cipher <= Cipher + Cipher_reg;
				end
				if(prm_ready && block_ctr == t-1)
					block_ctr <=0;
				else if(prm_ready && block_ctr !=t)
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
				if(en_start)
					state <= IDLE;
			end
			
			default: state <= IDLE;
			endcase
		end
	end
	
	//Signal update
	always @(*) begin
		Cipher_reg = 0;
		Tag_reg =0;
		en_ready_reg =0;
		case (state)
			IDLE: begin
				Cipher_reg =0;
				Tag_reg =0;
				en_ready_reg =0;
				prm_start =0;
				rounds = a;
				P_in = S;
			end
			
			INITIALIZE: begin
				Cipher_reg =0;
				Tag_reg =0;
				en_ready_reg =0;
				rounds = a;
//				if(prm_ready)
//					prm_start = 1;
//				else 
//					prm_start = 0;
				prm_start = (prm_ready)? 1'b0: 1'b1;
				P_in = S;
			end
			
			ASSOCIATED: begin
				Cipher_reg = 0;
				Tag_reg = 0;
				en_ready_reg =0;
				rounds =b;
				if(prm_ready && block_ctr == (s-1))
					prm_start = 0;
				else 
					prm_start = 1;
				P_in = {Sr^Asc_data[pad_A_length-1-(block_ctr*RATE)-:RATE], Sc};
				//extract RATE bit - aka take RATE-block associated data to process
			end
			
			PROCESS_PT: begin
				en_ready_reg =0;
				rounds =b;
				Tag_reg =0;
				Cipher_reg[pad_Pt_length-1-(block_ctr*RATE)-:RATE] = Sr ^Plain[pad_Pt_length-1-(block_ctr*RATE)-:RATE];
				P_in = {Sr ^ Plain[pad_Pt_length-1-(block_ctr*RATE)-:RATE], Sc};
				//same thing here
				if(block_ctr == (t-1))
					prm_start =0;
				else
					prm_start =1;
			end
			
			FINALIZE: begin
				Cipher_reg = 0;
				rounds =a; 
				P_in = S ^ ({{RATE{1'b0}}, key, {(c-KEY_l){1'b0}}});
				prm_start = (prm_ready)? 1'b0: 1'b1;
				en_ready_reg = 1'b0;
				Tag_reg = P_out ^ key;
			end
			
			DONE: begin
				Tag_reg =0;
				Cipher_reg =0;
				rounds =a;
				P_in = 0;
				prm_start =0;
				en_ready_reg =1;
			end
			
			default: begin
				Tag_reg =0;
				rounds = 0;
				P_in = S;
				prm_start =0;
				en_ready_reg =0;
				Cipher_reg=0;
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
//module round_en_ctr(
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
	
