`include "global_memory_parameters.v"

module top_tb();

wire Q; //output
reg D; //data input
reg SCK; //clock
reg S; //chip select
reg RESET; //reset
reg W_ENABLE;	 //write enable
reg clk;

spi_flash_memory uut
(	
	.clk(clk),
	.Q(Q),
	.D(D),
	.SCK(SCK),
	.S(S),
	.RESET(RESET),
	.W_ENABLE(W_ENABLE)
);

initial
begin
	RESET=1'b1;
	W_ENABLE=1'b1;
	SCK=1'b0;
	S=1'b1;
	D=1'b0;
	clk=1'b0;
end

always
begin
	#10 clk=!clk;
end

always
begin
	#65104 SCK=!SCK;
end	
	
always @ (negedge SCK)
begin
	#2604160 S<=1'b0; #130208
	D<=1'b1;#130208
	D<=1'b0;#130208
	D<=1'b0;#130208
	D<=1'b1;#130208
	D<=1'b1;#130208
	D<=1'b1;#130208
	D<=1'b1;#130208
	D<=1'b1;#130208
	D<=1'b0;S<=1'b0;#130208
	S<=1'b0;
end

endmodule 