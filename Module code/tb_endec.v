`timescale 1ns/1ps
module tb_endec;
	
	parameter k =128;
	parameter r =64;
	parameter a =12;
	parameter b =6;
	parameter A_l =112;
	parameter text_l = 128;
	parameter period = 5;
	parameter max = (k>=text_l && k>=A_l)? k: ((text_l>=A_l)? text_l:A_l);
	
	reg clk=0;
	reg rst;
	reg key_SI;
	reg nonce_SI;
	reg associated_SI;
	reg plaintext_SI;
	reg encryption_s_SI;
	reg decryption_s_SI;
	reg tag_in;
	integer ctr =0;
	reg [text_l-1:0] ciphertext, dec_plaintext;
	reg [127:0] tag, dec_tag;
	
	wire ciphertext_SO, dec_plaintext_SO;
	wire tag_SO, dectag_SO;
	wire encryption_r_SO;
	wire decryption_r_SO;
	wire msg_auth;
	integer time_check;
	integer plot =0;
	integer no =0;
	
//	parameter KEY = 'h00a14b66b34c7101e798a43505a17d58;
//	parameter NONCE = 'h33b1ba07991290964c7d834e82a9e9b7;
//    parameter AD = 'h4153434f4e;
//    parameter PT = 'h6173636f6e20576f726c6421;
//    parameter TAG = 'h0f21bf517921f2bbce3c3f02a6ee18da;
//    parameter TAG = 0;
    parameter KEY = 'h000102030405060708090A0B0C0D0E0F;
	parameter NONCE = 'h000102030405060708090A0B0C0D0E0F;
    parameter AD = 'h000102030405060708090a0b0c0d;
    parameter PT = 'h000102030405060708090a0b0c0d0e0f;
    parameter TAG = 'h526e4b15b4b3184a2fc1f7d160e4e972;
//    parameter KEY = 'hb7234a4db9fb8b7c2aa5735ebef1180c;
//	parameter NONCE = 'h8ebb295da81c74b58306d4e8362e2242;
//    parameter AD = 'h4153434f4e;
//    parameter PT = 'h6173636f6e;
	
	ascon#(
		k,
		r,
		a,
		b,
		A_l,
		text_l
	) uut (
		clk,
		rst,
		key_SI,
		nonce_SI,
		associated_SI,
		plaintext_SI,
		encryption_s_SI,
		decryption_s_SI,
		tag_in,
		ciphertext_SO,
		dec_plaintext_SO,
		tag_SO,
		dectag_SO,
		encryption_r_SO,
		decryption_r_SO,
		msg_auth
	);
	
	//Generate clock 5ns
	always #(period) clk = ~clk;
	
	task set_value;
	input [max-1:0] i,key,nonce,ass,pt,tag_in_reg;
	begin
		@(posedge clk);
		key_SI = key[k-1-i];
		nonce_SI = nonce[127-i];
		plaintext_SI = pt[text_l-1-i];
		associated_SI = ass[A_l-1-i];
		tag_in = tag_in_reg[127-i];
	end
	endtask
	
	task export_enc;
	input integer i;
	begin
		@(posedge clk);
		ciphertext[i] = ciphertext_SO;
		tag[i] = tag_SO;
	end
	endtask
	
	task export_dec;
	input integer i;
	begin
		@(posedge clk);
		dec_plaintext[i] = dec_plaintext_SO;
		dec_tag[i] = dectag_SO;
	end
	endtask
	
	initial begin
		$display("Start");
		rst = 1;
		#(1.5*period)
		rst =0;
		no=1;
		ctr =0;
		repeat(max) begin
			set_value(ctr, KEY, NONCE, AD, PT, TAG);
			ctr = ctr+1;
		end
		ctr =0;
		encryption_s_SI = 1;
		time_check = $time;
		#(0.5*period)
		$display("Key: \t%h", uut.key);
		$display("Nonce: \t%h", uut.nonce);
		$display("Associated: \t%h", uut.associated);
		$display("Plaintext: \t%h", uut.plaintext);
//		$display("Plaintext: \t%h", uut.plaintext);
		
		#(4.5*period)
		encryption_s_SI = 0;
	end
	
	always @(*) begin
		if(encryption_r_SO & plot == 0 ) begin
			plot = 1;
			time_check = $time - time_check;
			$display("Done encryption in %d clock cycles", time_check/(2*period));
			#(4*period)
			repeat(max) begin
				export_enc(ctr);
				ctr = ctr + 1;
			end
			$display("Ciphertext:\t%h", ciphertext);
			$display("Tag:\t%h", tag);
			decryption_s_SI = 1;
			time_check = $time;
			ctr =0;
			#(5*period)
			decryption_s_SI = 0;
		end
		
		if(decryption_r_SO) begin
			time_check = $time - time_check;
			$display("Done decryption in %d clock cycles", time_check/(2*period));
			#(4*period)
			repeat (max) begin
				export_dec(ctr);
				ctr = ctr +1;
			end
			$display("PT: \t%h", dec_plaintext);
			$display("Tag: \t%h", dec_tag);
			$display("Authenticated: \t%b", msg_auth);
			$finish;
		end
	end
endmodule