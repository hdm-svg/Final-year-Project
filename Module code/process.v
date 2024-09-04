`timescale 1ns/1ps
module processing#(
	parameter KEY_l = 128,
	parameter RATE = 128,
	parameter a = 12,
	parameter b = 6 ,
	parameter A_l = 40,
	parameter text_l = 40
)(
	input clk,
	input rst,
	input [KEY_l-1:0] key,
	input [127:0] nonce,
	input [A_l -1:0] associated,
	input [text_l -1:0] plaintext,
	input [127:0] tag_in,
	input en_start,
	input dec_start,
	
	output [text_l -1:0] ciphertext,
	output [text_l -1:0] dec_Pt,
	output [127:0] tag,
	output [127:0] dec_tag,
	output en_ready,
	output dec_ready,
	output msg_auth
);
	encryption #(
		KEY_l,
		RATE,
		a,
		b,
		A_l,
		text_l
	)en(
		clk,
		rst,
		key,
		nonce,
		associated,
		plaintext,
		en_start,
		ciphertext,
		tag,
		en_ready
	);
	
	decryption #(
		KEY_l,
		RATE,
		a,
		b,
		A_l,
		text_l
	)de(
		clk,
		rst,
		key,
		nonce,
		associated,
		ciphertext,
//		tag_in,
		dec_start,
		dec_Pt,
		dec_tag,
		dec_ready
	);
	
//	if(de_ready)
//		assign msg_auth = 1;
//	else
//		assign msg_auth = 0;
	assign msg_auth = (dec_ready)? (dec_tag == tag_in):0;
endmodule