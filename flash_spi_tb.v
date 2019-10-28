`include "global_memory_parameters.v"

module flash_spi_tb();
reg SCK,S,RESET,W_ENABLE,DATA_DONE;
reg [7:0] D;
wire [7:0] Q;

memory uut(
.SCK(SCK),
.S(S),
.RESET(RESET),
.W_ENABLE(W_ENABLE),
.D(D),
.Q(Q),
.DATA_DONE(DATA_DONE)
);

initial
begin
	RESET=1'b0;
	W_ENABLE=1'b1;
	SCK=1'b0;
	S=1'b1;
	D=8'h00;
	DATA_DONE=1'b0;
end

always
	#65104 SCK=!SCK;
	
always @ (posedge SCK)
begin
	//WREN
	#1302080 DATA_DONE=1'b1; #130208
	DATA_DONE=1'b0; S=1'b0; RESET=1'b1;D=`RDID; #130208
	S=1'b0;
end	
endmodule
	