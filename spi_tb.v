`include "global_memory_parameters.v"

module spi_tb();
reg MOSI,SPI_SCK,SPI_RESET,SPI_S,clk;
wire DATA_DONE;
reg [7:0] Q;
wire MISO,RESET,S;
wire [7:0] D;

spi_ip_core uut(
	.clk(clk),
	.MOSI(MOSI), 
	.SPI_SCK(SPI_SCK),
	.SPI_RESET(SPI_RESET),
	.SPI_S(SPI_S),
	.MISO(MISO),
	.D(D),
	.RESET(RESET),
	.S(S),
	.Q(Q),
	.DATA_DONE(DATA_DONE)
);

initial
begin
	MOSI=1'b0;
	SPI_SCK=1'b0;
	SPI_RESET=1'b1;
	SPI_S=1'b1;
	Q=8'h00;
	clk=1'b0;
end

always 
begin
	#10 clk=!clk;
end

always
begin
	#65104 SPI_SCK=!SPI_SCK;
end

always @ (negedge SPI_SCK)
begin	
	#130208 SPI_S=1'b0;
	MOSI=1'b0; #130208 //dummy
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; Q=8'hAA; #130208 
	
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b0; #130208 
	MOSI=1'b0; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b1; #130208 
	MOSI=1'b0; #130208 
	SPI_S=1'b1;
   /*MOSI=1'b0; #20 
	MOSI=1'b1; #20 
	MOSI=1'b0; #20 
	MOSI=1'b1; #20 
	MOSI=1'b1; #20 
	MOSI=1'b0; #20 
	MOSI=1'b1; #20
	MOSI=1'b0;*/
end

endmodule 