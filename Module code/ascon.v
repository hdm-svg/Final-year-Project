`timescale 1ns/1ps
module ascon #(
	parameter KEY_l =128,
	parameter RATE = 64,
	parameter a = 12,             
    parameter b = 6,              
    parameter A_l = 40,            
    parameter text_l = 40          
)(
	input clk,
	input rst,
	//Serial Input
	input key_in,
	input nonce_in,
	input associated_in,
	input plaintext_in,
	input en_start_in,
	input dec_start_in,
	input tag_in,
	
	
	//Serial Output
	output reg ciphertext_o,
	output reg plaintext_o,
	output reg tag_o,
	output reg dectag_o,
	output en_ready_o,
	output de_ready_o,
	output msg_auth
);
	//store value buffer
	reg [KEY_l-1:0] key;
	reg	[127:0] nonce;
	reg [A_l-1:0] associated;
	reg [text_l-1:0] plaintext;
	reg [127:0] tag;
	reg [31:0] cnt_key_in, cnt_en_out, cnt_dec_out;
	wire [text_l-1:0] dec_Pt;
	wire [text_l-1:0] ciphertext;
	wire [127:0] tag_reg;
	wire [127:0] dec_tag_reg;
	wire ready; //ping to check on
	wire en_start;
	
	wire en_ready;
	wire de_ready;


	
	//Input Serial
	always @(posedge clk) begin
		if(rst) begin
			key <= 0;
			nonce <= 0;
			associated <= 0;
			plaintext <= 0;
			tag <= 0;
			cnt_key_in <=0;
			cnt_en_out <= 0;
			cnt_dec_out <= 0;
		end
		else begin
			if (cnt_key_in<KEY_l) begin 
				key <= {key[KEY_l-2:0],key_in};
				nonce <= {nonce[KEY_l-2:0], nonce_in};
				tag <= {tag[KEY_l-2:0], tag_in};
			end				
			if(cnt_key_in < A_l) 
				associated <= {associated[A_l-2:0], associated_in};
			if(cnt_key_in < text_l)
				plaintext <= {plaintext[text_l-2:0], plaintext_in};

			cnt_key_in <= cnt_key_in + 1;
		end
	
	//Output Serial
		if(en_ready) begin
			if(cnt_en_out < text_l)
				ciphertext_o <= ciphertext[cnt_en_out];
			if(cnt_en_out < 128)
				tag_o <= tag_reg[cnt_en_out];
			cnt_en_out <= cnt_en_out +1;
		end
		
		if(de_ready) begin
			if(msg_auth) begin
				if(cnt_dec_out < text_l)
					plaintext_o <= dec_Pt[cnt_dec_out];
				if(cnt_dec_out < 128)
					dectag_o <= dec_tag_reg[cnt_dec_out];
				cnt_dec_out <= cnt_dec_out +1;
			end
			//if not authenticated output default msg (all 1)
			else begin
				if(cnt_dec_out < text_l)
					plaintext_o <= 1;
				if(cnt_dec_out < 128)
					dectag_o <= 1;
				cnt_dec_out <= cnt_dec_out +1;
			end
		end
	end
	
	assign ready = ((cnt_key_in > KEY_l) && (cnt_key_in >128) && (cnt_key_in> A_l) && (cnt_key_in > text_l))? 1: 0;
	assign en_start = ready & en_start_in;
	assign en_ready_o = en_ready;
	assign de_ready_o = de_ready;
	
	processing #(
		KEY_l,
		RATE,
		a,
		b,
		A_l,
		text_l
	) pr(
		clk,
		rst,
		key,
		nonce,
		associated,
		plaintext,
		tag,
		en_start,
		dec_start_in,
		ciphertext,
		dec_Pt,
		tag_reg,
		dec_tag_reg,
		en_ready,
		de_ready,
		msg_auth
	);
endmodule