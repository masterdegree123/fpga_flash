`include "global_memory_parameters.v"

module memory(
output reg [7:0] Q, //output
input [7:0] D, //data input
input SCK, //clock
input S, //chip select
input RESET, //reset
input W_ENABLE	, //write enable
input DATA_DONE //revice data from SPI
);

reg sck_val=1'b0; //value of clock
reg s_flag=1'b0; //select active flag
reg rst_flag=1'b0; //reset active flag
reg hpm_flag=1'b0; //Hardware Protection Mode active flag
reg busy_flag=1'b0; //check if other instruction are executed

reg [7:0] data_buff=8'h00; //input data buffor
reg [7:0] data_done=8'h00; //input data save for memory
reg [7:0] q_buff=8'h00; //output data buffor

reg cnt_flag=1'b0; //counter active flag
reg [11:0] cnt_byte=12'h000; //byte counter

time dp_time;//time counting for DP
time rdp_time;//time counting for RDP

reg rdid_flag=1'b0; //RDID instruction status
reg [23:0] mem_id={`man_id, `mem_typ, `mem_cap}; //Memory ID, Memory Typ, Memory Capacity
reg [2:0]rdid_cnt=3'b000; //rdid bit counter

reg read_flag=1'b0; //READ instruction status
reg fast_read_flag=1'b0; //FAST READ instruction status
reg page_erase_flag=1'b0; //PAGE ERASE instruction status
reg section_erase_flag=1'b0; //SECTOR ERASE instruction status
reg page_write_flag=1'b0; //PAGE WRITE instruction status
reg page_prog_flag=1'b0; //PAGE PROGRAMMING instruction status
reg wren_flag=1'b0; //WREN instruction status
reg wrdi_flag=1'b0; //WRDI instruction status
reg rdsr_flag=1'b0; //RDSR instruction status
reg dp_flag=1'b0; //DP instruction status
reg rdp_flag=1'b0; //RDP instruction status

reg [7:0] rdsr_reg=8'h00; //RDSR register

reg [23:0] mem_add=24'h000000; //addres in memory
reg [23:0] mem_add_sec=24'h000000; //sector addres
reg [23:0] mem_add_page=24'h000000; //page addres
reg add_done_flag=1'b0; //adres reading end flag

reg [3:0] read_cnt=4'h0;//read bit counter
reg read_busy=1'b0; //reading bits from current addres

reg section_erase_busy=1'b0; //SE process working flag
reg page_erase_busy=1'b0; //PE process working flag

reg page_prog_busy=1'b0; //PP process working flag
integer page_cnt=0; //readed byte counter

reg page_write_busy=1'b0; //PW write process working flag
reg pw_erase_busy=1'b0; //PW erase process working flag

reg [7:0] read_data=8'h00; //readed data

reg dp_mode=1'b0; //Deep Power Mode status

integer i=0; //variable using in for loop
integer j=0; //variable using in for loop

reg [7:0] mem_content[(`size-1):0]; //content of memory
initial 
begin
	for(i=0;i<=`size-1;i=i+1) //initial memory content
	begin
		mem_content[i]<=8'hFF;
	end
end

reg [7:0] page_content[(`page_size-1):0]; //content to save in page
initial 
begin
	for(i=0;i<=`page_size-1;i=i+1) //initial memory content
	begin
		page_content[i]<=8'hFF;
	end
end
//================SIGNAL LACHING================

//save current clock value
always @ (SCK)
begin
	sck_val<=SCK;
end

//Hardware Protected mode status
always @ (W_ENABLE)
begin
	if(!W_ENABLE)
	begin
		hpm_flag<=1'b1;
	end
	else
	begin
		hpm_flag<=1'b0;
	end
end
//=============INPUT READ==============
//read input
always @ (negedge DATA_DONE)
begin
	if(s_flag && !rst_flag)
	begin
	data_buff<=D;
	cnt_byte<=cnt_byte+1;
	end
	
	if(!s_flag)
	begin
		data_buff<=8'h00;
		cnt_byte<=0;
	end
end

always @ (data_buff or cnt_byte or s_flag)
begin
//=============INPUT DATA USING==============
	//instruction
	if(s_flag)
	begin
		if(cnt_byte==12'h001 && !busy_flag)
		begin
			if(!rdsr_reg[0])
			begin
				case(data_buff)
					`RDID: 
					begin 
						rdid_flag<=1'b1;
						$display("%t-RDID instruction",$realtime);
					end
					`READ:
					begin 
						read_flag<=1'b1;
						$display("%t-READ instruction",$realtime);
					end
					`FAST_READ:
					begin 
						fast_read_flag<=1'b1;
						$display("%t-FAST READ instruction",$realtime);
					end
					`WREN:
					begin
						wren_flag<=1'b1;
						$display("%t-WREN instruction",$realtime);
					end
					`WRDI:
					begin
						wrdi_flag<=1'b1;
						$display("%t-WRDI instruction",$realtime);
					end
					`DP:
					begin
						dp_flag<=1'b1;
						$display("%t-DP instruction",$realtime);
					end
					`RDP:
					begin
						rdp_flag<=1'b1;
						$display("%t-RDP instruction",$realtime);
					end
					`SE:
					begin
						section_erase_flag<=1'b1;
						$display("%t-SE instruction",$realtime);
					end
					`PE:
					begin
						page_erase_flag<=1'b1;
						$display("%t-PE instruction",$realtime);
					end
					`PW:
					begin
						page_write_flag<=1'b1;
						$display("%t-PW instruction",$realtime);
					end
					`PP:
					begin
						page_prog_flag<=1'b1;
						$display("%t-PP instruction",$realtime);
					end
					`RDSR:
					begin
						rdsr_flag<=1'b1;
						$display("%t-RDSR instruction",$realtime);
					end
					default :
					begin
						$display("%t-No such command 1",$realtime);
						q_buff<=1'bX;
					end
				endcase
			end
			
			else if(data_buff==`RDSR)
			begin
				rdsr_flag<=1'b1;
				//$display("%t-RDSR instruction",$realtime);				
			end
			else if(busy_flag)
			begin
				$display("%t-Other process is running",$realtime);
			end
			else if(rdsr_reg[0])
			begin
				$display("%t-Other process is running, only RDSR instruction will be accepted",$realtime);
			end
			else
			begin
				$display("%t-No such command 2",$realtime);
				q_buff<=1'bX;
			end
		end
		//addres 1
		if(cnt_byte==12'h002 && (fast_read_flag || read_flag || section_erase_flag || page_erase_flag || page_write_flag || page_prog_flag))
		begin
			mem_add[23:16]<=data_buff;
		end
		//addres 2
		if(cnt_byte==12'h003 && (fast_read_flag || read_flag || section_erase_flag || page_erase_flag || page_write_flag || page_prog_flag))
		begin
			mem_add[15:8]<=data_buff;
		end
		//addres 3
		if(cnt_byte==12'h004 && (fast_read_flag || read_flag || section_erase_flag || page_erase_flag || page_write_flag || page_prog_flag))
		begin
			mem_add[7:0]<=data_buff;
			add_done_flag<=1'b1;
		end
		//input data for programming or write
		if(cnt_byte>12'h004 && (page_write_flag || page_prog_flag))
		begin
			page_content[cnt_byte-5]<=data_buff;
			page_cnt=page_cnt+1;
		end
		
		
		//Page addres
		if(add_done_flag && (page_erase_flag || page_write_flag || page_prog_flag))
		begin
			mem_add_page<=mem_add&`page_board;
		end

		//Sector addres
		if(add_done_flag && section_erase_flag)
		begin
			mem_add_sec<=mem_add&`sector_bord;
		end
	end
	
	//=========INSTRUCTIONS==============
	if(rdid_flag && s_flag && !rst_flag && !dp_mode)
	begin
		busy_flag<=1'b1;
		if(rdid_cnt==3'b000)
		begin
			q_buff<=mem_id[23:16];
		end
		else if(rdid_cnt==3'b001)
		begin
			q_buff<=mem_id[15:8];
		end
		else if(rdid_cnt==3'b010)
		begin
			q_buff<=mem_id[7:0];
		end
		
		if(rdid_cnt>3'b010)
		begin
			q_buff<=8'h00;
		end
		else
		begin
			rdid_cnt<=rdid_cnt+1;
		end
	end
	else if(rdid_flag && (!s_flag || rst_flag))
	begin
		q_buff<=8'hZZ;
	end
//-------------RDSR---------------
	if(rdsr_flag && s_flag && !rst_flag && !dp_mode)
	begin
		busy_flag<=1'b1;
		q_buff<=rdsr_reg;
	end
//---------WREN----------
	if(wren_flag && !s_flag && !rst_flag && !dp_mode)
	begin
		$display("%t-WEL register to TRUE",$realtime);
		rdsr_reg[1]<=1'b1;
		wren_flag<=1'b0;
	end
//---------WRDI----------
	if(wrdi_flag && !s_flag && !rst_flag && !dp_mode)
	begin
		$display("%t-WEL register to FALSE",$realtime);
		rdsr_reg[1]<=1'b0;
		wrdi_flag<=1'b0;
	end
	
	//---------READ----------
	if(read_flag)
	begin
		if(!add_done_flag && !s_flag)
		begin
			//$display("$t-Instruction was too early deselect",$realtime);
			read_flag<=1'b0;
		end
		else if(read_flag && add_done_flag && !rst_flag && !dp_mode && s_flag && !read_busy)
		begin
			busy_flag<=1'b1;
			read_busy<=1'b1;
			read_data<=mem_content[1];
			if(mem_add==24'h0FFFFF)
			begin
				mem_add<=24'h000000;
			end
			else
			begin
				mem_add<=mem_add+1;
			end
			//$display("%t-Read addres %h",$realtime,mem_add);
		end
	end

	if(read_flag && s_flag && !rst_flag && add_done_flag && read_busy && !dp_mode)
	begin
		q_buff<=#`t_clqv read_data[7-read_cnt];
		if(read_cnt>=4'h7)
		begin
			read_cnt<=4'h0;
			read_busy<=1'b0;
		end
		else
		begin
			read_cnt<=read_cnt+1;
		end
	end

//---------DP----------
	if(dp_flag && !dp_mode && !rst_flag && !s_flag)
	begin
		dp_time=10;//$time;
	end
//---------RDP----------
	if(rdp_flag && dp_mode && !rst_flag && !s_flag)
	begin
		rdp_time=10;//$time;
	end

//---------SE----------
	if(section_erase_flag)
	begin
		if(!s_flag)
		begin
			if(!add_done_flag)
			begin
				//$display("$t-Instruction was too early deselect, adres is incomplite",$realtime);
				section_erase_flag<=1'b0;
			end
			else if(add_done_flag && hpm_flag && mem_add_sec<=`protect_board)
			begin
				//$display("%t-This sector is under Hardware Protection Mode",$realtime);
				add_done_flag<=1'b0;
				section_erase_flag<=1'b0;
			end
			else if (add_done_flag && !rdsr_reg[1])
			begin
				//$display("%t-WEL bit is turn off",$realtime);
				add_done_flag<=1'b0;
				section_erase_flag<=1'b0;
			end
		end
	end

	if(section_erase_flag && add_done_flag && !rst_flag && !dp_mode && !s_flag)
	begin
		section_erase_busy<=1'b1;
		$display("%t-Sector Erase - Start",$realtime);
		rdsr_reg[0]<=1'b1;
		//real time delay
		//#`t_pe_typ;
		#5000;
		section_erase_flag<=1'b0;
	end

	//Erase sector after delay time
	if(!section_erase_busy)
	begin
		for(i=mem_add_sec;i<=mem_add_sec+`sector_size-1;i=i+1)
		begin
			mem_content[i]<=8'hFF;
		end
		add_done_flag<=1'b0;
		section_erase_flag<=1'b0;
		rdsr_reg[0]<=1'b0;
		$display("%t-Sector Erase - Stop",$realtime);
end

//---------PE----------
	if(page_erase_flag)
	begin
		if(!s_flag)
		begin
			if(!add_done_flag)
			begin
				$display("$t-Instruction was too early deselect",$realtime);
				page_erase_flag<=1'b0;
			end
			else if(add_done_flag && hpm_flag && mem_add_page<=`protect_board)
			begin
				$display("%t-This sector is under Hardware Protection Mode",$realtime);
				add_done_flag<=1'b0;
				section_erase_flag<=1'b0;
			end
			else if (add_done_flag && !rdsr_reg[1])
			begin
				$display("%t-WEL bit is turn off",$realtime);
				add_done_flag<=1'b0;
				page_erase_flag<=1'b0;
			end
		end
	end

	if(page_erase_flag && add_done_flag && !rst_flag && !dp_mode && !s_flag)
	begin
		page_erase_busy<=1'b1;
		$display("%t-Page Erase - Start",$realtime);
		rdsr_reg[0]<=1'b1;
		//real time delay
		//#`t_pe_typ;
		#5000;
		page_erase_busy<=1'b0;
	end

//Erase page after delay time
if(!page_erase_busy)
begin
	for(i=mem_add_page;i<=mem_add_page+`page_size-1;i=i+1)
   begin
		mem_content[i]<=8'hFF;
	end
	add_done_flag<=1'b0;
	page_erase_flag<=1'b0;
	rdsr_reg[0]<=1'b0;
	$display("%t-Page Erase - Stop",$realtime);
end

//---------PW----------
	if(page_write_flag)
	begin
		if(!s_flag)
		begin
			if(!add_done_flag)
			begin
				$display("$t-Instruction was too early deselect",$realtime);
				page_write_flag<=1'b0;
			end
			else if(add_done_flag && hpm_flag && mem_add_page<=`protect_board)
			begin
				$display("%t-This sector is under Hardware Protection Mode",$realtime);
				add_done_flag<=1'b0;
				page_write_flag<=1'b0;
			end
			else if(add_done_flag && !rdsr_reg[1])
			begin
				$display("%t-WEL bit is turn off",$realtime);
				add_done_flag<=1'b0;
				page_write_flag<=1'b0;
			end
		end
	end

	if(page_write_flag && add_done_flag && !rst_flag && !dp_mode && !s_flag)//&& $time!=0)
	begin
		rdsr_reg[0]<=1'b1;
		pw_erase_busy<=1'b1;
		$display("%t-Page Write- Erase Start",$realtime);
		//real time delay
		//#`t_pe_typ
		#50;
		pw_erase_busy<=1'b0;
	end

if(!pw_erase_busy)
begin
	for(i=mem_add_page;i<=mem_add_page+`page_size-1;i=i+1)
   begin
		mem_content[i]<=8'hFF;
	end
	//$display("%t-Page Write- Erase Stop",$realtime);
	page_write_flag<=1'b1;
end


//Write page after erase
if (!pw_erase_busy)
begin
	begin
		for(j=0;j<=`page_size-1;j=j+1)
		begin
			mem_content[mem_add_page+j]<=mem_content[mem_add_page+j]&page_content[j];
		end
		add_done_flag<=1'b0;
		page_prog_flag<=1'b0;
		rdsr_reg[0]<=1'b0;
		page_cnt<=1'b0;
		for(i=0;i<=`page_size;i=i+1) //initial memory content
		begin
			page_content[i]<=8'hFF;
		end
		$display("%t-Page Programming - Stop",$realtime);
	end
end
//---------PP----------
	if(page_prog_flag)
	begin
		if(!s_flag)
		begin
			if(!add_done_flag)
			begin
				//$display("$t-Instruction was too early deselect",$realtime);
				page_prog_flag<=1'b0;
			end
			else if(add_done_flag && hpm_flag && mem_add_page<=`protect_board)
			begin
				//$display("%t-This sector is under Hardware Protection Mode",$realtime);
				add_done_flag<=1'b0;
				page_prog_flag<=1'b0;
			end
			else if(add_done_flag && !rdsr_reg[1])
			begin
				//$display("%t-WEL bit is turn off",$realtime);
				add_done_flag<=1'b0;
				page_prog_flag<=1'b0;
			end
		end
	end

	if(page_prog_flag && add_done_flag && !rst_flag && !dp_mode && !s_flag)// && $time!=0)
	begin
		rdsr_reg[0]<=1'b1;
		page_prog_busy<=1'b1;
		//$display("%t-Page Programming- Start",$realtime);
		//real time delay
		//#`t_pp_256_typ
		#5000
		page_prog_busy<=1'b0;
	end

//Programing page after delay time
if(!page_prog_busy)
begin
//if($time!=0)
	begin
		for(j=0;j<=`page_size-1;j=j+1)
		begin
			mem_content[mem_add_page+j]<=mem_content[mem_add_page+j]&page_content[j];
		end
		add_done_flag<=1'b0;
		page_prog_flag<=1'b0;
		rdsr_reg[0]<=1'b0;
		page_cnt<=1'b0;
		for(i=0;i<=`page_size;i=i+1) //initial memory content
		begin
			page_content[i]<=8'hFF;
		end
		//$display("%t-Page Programming - Stop",$realtime);
	end
end
	
	else if (!s_flag || rst_flag)
	begin
		rdid_cnt<=3'b000;
		q_buff<=8'hZZ;
		rdid_flag<=8'h00;
		rdsr_flag<=8'h00;
		busy_flag<=1'b0;
	end
end
/*

*/
//---------SELECT AND RESET----------

//select pin status
always @ (S)
begin
	if(!S)
	begin
		s_flag<=1'b1;
		//dp_flag<=1'b0;
		//rdp_flag<=1'b0;
	end
	else
	begin
		s_flag<=1'b0;
		if(dp_flag)
		begin
			if(/*$time*/10-dp_time<=`t_dp)
			begin
				//$display("Device need be no selected for DP");
			end
			else
			begin
				//$display("Device is in DP Mode");
				dp_mode<=1'b1;
			end
		end
		
		if(rdp_flag)
		begin
			if(/*$time*/10-rdp_time<=`t_rdp)
			begin
				//$display("Device need be no selected for RDP");
			end
			else
			begin
				//$display("Device is in Stand By Mode");
				dp_mode<=1'b0;
			end
		end
	end
end

//Reset status
always @ (RESET)
begin
	if(RESET)
	begin
		rst_flag<=1'b0;
	end
	else
	begin
		rst_flag<=1'b1;
		/*
		rdsr_reg[0]<=1'b0;
		cnt_flag=1'b0; //counter active flag
		cnt_byte=12'h000; //byte counter
		
		rdid_flag=1'b0; //RDID instruction status
		rdid_cnt<=3'b000;
		
		read_flag=1'b0; //READ instruction status
		fast_read_flag=1'b0; //FAST READ instruction status
		page_erase_flag=1'b0; //PAGE ERASE instruction status
		section_erase_flag=1'b0; //SECTOR ERASE instruction status
		page_write_flag=1'b0; //PAGE WRITE instruction status
		page_prog_flag=1'b0; //PAGE PROGRAMMING instruction status
		wren_flag=1'b0; //WREN instruction status
		wrdi_flag=1'b0; //WRDI instruction status
		rdsr_flag=1'b0; //RDSR instruction status
		
		section_erase_busy<=1'b0;*/
	end
end

//=============OUTPUT==============
always @ (q_buff)
begin
	Q<=q_buff;
end

endmodule