module spi_flash_memory
(
	input clk, //system clock
	output wire Q, //output
	input D, //data input
	input SCK, //clock
	input S, //chip select
	input RESET, //reset
	input W_ENABLE	 //write enable
);

reg SPI_S; //Select signal
wire [7:0] SPI_D_MEM; //input memory
wire SPI_RESET_MEM; //reset memory
wire SPI_S_MEM; //select memory
wire DATA_DONE_SPI;// done flag from SPI
reg DATA_DONE_MEM;// done flag from SPI
reg [7:0] MEM_Q_SPI; //output memory
wire [7:0] MEM_Q; //output
reg [7:0] MEM_D; //data input
reg MEM_S; //chip select
reg MEM_RESET; //reset

spi_ip_core spi_module(
	.clk(clk),
	.MOSI(D), //SPI input
	.SPI_SCK(SCK),//SPI clock
	.SPI_RESET(RESET),//SPI Reset
	.SPI_S(S),//SPI select signal
	.MISO(Q), //SPI output
	.D(SPI_D_MEM), //SPI output - memory input
   .RESET(SPI_RESET_MEM), //SPI reset - memory rest
	.S(SPI_S_MEM), //SPI select -> Memory select
	.DATA_DONE(DATA_DONE_SPI),// Data done signal -> Memory data done signal
	.Q(MEM_Q_SPI) //Memory output -> SPI input
);

memory memory_module(
	.Q(MEM_Q), //memory output
	.D(MEM_D), //memory input
	.SCK(SCK), //clock
	.S(MEM_S), //select signal
	.RESET(MEM_RESET), //reset signal
	.W_ENABLE(W_ENABLE),//write enable signal
	.DATA_DONE(DATA_DONE_MEM)//data done signal
);

always @ (*)
begin
	MEM_D<=SPI_D_MEM;
	MEM_Q_SPI<=MEM_Q;
	DATA_DONE_MEM<=DATA_DONE_SPI;
	MEM_S<=SPI_S_MEM;
end

endmodule 