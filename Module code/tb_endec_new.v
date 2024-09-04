`timescale 1ns/1ps
module tb_endec_new;
	
	parameter k =128;
	parameter r =64;
	parameter a= 12;
	parameter b= 6;
	parameter A_l =40;
	parameter text_l = 40;

	parameter period = 20;
	parameter max = (k>=text_l && k>=A_l)? k: ((text_l>=A_l)? text_l:A_l);
	
	reg clk=0;
	reg rst;
	reg key_SI;
	reg nonce_SI;
	reg associated_SI;
	reg plaintext_SI;
	reg encryption_s_SI;
	reg decryption_s_SI;
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
	integer j;
	integer no=0;
	
	reg [127:0] test_keys[0:2];
	reg [127:0] test_nonce[0:2];
	reg [A_l-1:0] test_AD[0:2];
	reg [text_l-1:0] test_PT[0:2];
	
	
	
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
		ciphertext_SO,
		dec_plaintext_SO,
		tag_SO,
		dectag_SO,
		encryption_r_SO,
		decryption_r_SO,
		msg_auth
	);
	
	//Generate clock 10ns
	always #(period) clk = ~clk;
	
	task set_value;
	input [max-1:0] i,key,nonce,ass,pt;
	begin
		@(posedge clk);
		key_SI = key[k-1-i];
		nonce_SI = nonce[127-i];
		plaintext_SI = pt[text_l-1-i];
		associated_SI = ass[A_l-1-i];
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
	
		task process_encryption;
		 begin
//		    @(*) begin
			while (!encryption_r_SO || plot!=0)  @(posedge clk); 
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
		    
		end
		
	endtask
	
	task process_decryption;
		begin
//		    @(*) begin
			while (!decryption_r_SO)@(posedge clk);
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
			
			plot = 0;
		    
		end
		
	endtask
	
	initial begin
		$display("Start");
		
		//initialize test vectors
		test_keys[0] = 'h00a14b66b34c7101e798a43505a17d58;
		test_nonce[0] = 'h33b1ba07991290964c7d834e82a9e9b7;
		test_AD[0] = 'h4153434f4e;
		test_PT[0] = 'h6173636f6e;
		//058d7f924a
		test_keys[1] = 'h3ffa75efbd1705fa8f9ced62e5bb0be3;
		test_nonce[1] = 'h9691163337dd55217ea2a6b21eaa19b2;
		test_AD[1] = 'h4153434f4e;
		test_PT[1] = 'h6173636f6e;	
		//c21061905f
		test_keys[2] = 'hb7234a4db9fb8b7c2aa5735ebef1180c;
		test_nonce[2] = 'h8ebb295da81c74b58306d4e8362e2242;
		test_AD[2] = 'h4153434f4e;
		test_PT[2] = 'h6173636f6e;
		//80cdf888e3
		//end of test vectors
		for(j =0; j<3;j = j+1) begin
			$display("Test case %d",j+1);
			rst = 1;
			#(1.5*period)
			rst =0;
			
			ctr =0;
			repeat(max) begin
				set_value(ctr, test_keys[j], test_nonce[j], test_AD[j], test_PT[j]);
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
			
//			#(77*period)
            #(4.5*period)
			encryption_s_SI = 0;
			
			process_encryption();
			

			decryption_s_SI = 1;
			time_check = $time;
			ctr =0;
//			#(76.5*period)
            #(5*period)
			decryption_s_SI = 0;
			process_decryption();
				
		end
		$finish;
	end

			
endmodule