module SEG7_LUT	(
    idata, 
    oSEG
);

input	      [3:0]	idata;
output	reg [6:0]	oSEG;

always @(*)
begin
		case(idata)
		4'h1: oSEG = 7'b1111001;	
		4'h2: oSEG = 7'b0100100; //0x24
		4'h3: oSEG = 7'b0110000; //0x30	
		4'h4: oSEG = 7'b0011001; 	
		4'h5: oSEG = 7'b0010010; 
		4'h6: oSEG = 7'b0000010; 	
		4'h7: oSEG = 7'b1111000; 	
		4'h8: oSEG = 7'b0000000; 	
		4'h9: oSEG = 7'b0011000; 	
		4'ha: oSEG = 7'b0001000;  //A
		4'hb: oSEG = 7'b0000011;  //b
		4'hc: oSEG = 7'b1000110;  //C
		4'hd: oSEG = 7'b0100001;  //d
		4'he: oSEG = 7'b0000110;  //E
		4'hf: oSEG = 7'b0001110;  //F
		4'h0: oSEG = 7'b1000000;  //0	//0x40
		endcase
end

endmodule
