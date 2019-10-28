`define size 1000//1048576 // memory size [byte] 
`define wwidth 8 //word width [bit]
`define sector_size 65536 //sector size [byte]
`define page_size 256//page size [byte]
`define sector_bord 24'h0F0000
`define page_board 24'h0FFF00
`define protect_board 24'h010000 //board of Hardware Protect Mode

//24bit JEDEC
`define man_id 8'h20//Manufacturer Identification
`define mem_typ 8'h40//Memory Type 
`define mem_cap 8'h14//Memory Capacity

//instruction
`define RDID 8'h9F
`define READ 8'h03
`define RDSR 8'h05
`define WREN 8'h06
`define WRDI 8'h04
`define PW 8'h0A
`define PP 8'h02
`define PE 8'hDB
`define SE 8'hD8
`define FAST_READ 8'h0B
`define DP 8'hB9
`define RDP 8'hAB

//times from datasheet for 50MHz
`define t_slch 5 //S active setup time [ns]
`define t_chsl 5 //S not active hold time [ns]
`define t_dvch 2 //Data in setup time [ns]
`define t_chdx 5 //Data in hold time [ns]
`define t_chsh 5 //S active hold time [ns]
`define t_shch 5 //S not active setup time [ns]
`define t_shsl 100//S deselect time [ns]
`define t_shqz 8//Output disable time [ns]
`define t_clqv 8 //Clock Low to Output Valid [ns]
`define t_clqx 0 //Output hold time [ns]
`define t_whsl 50//Write Protect setup time [ns]
`define t_shwl 100//Write Protect hold time [ns]
`define t_dp 3000//S to Deep Power-down [ns]
`define t_rdp 30000//S High to Standby mode [ns]
`define t_rlrh 10000//Reset pulse width [ns]
`define t_rhsl 3000//Reset recovery time [ns]
`define t_shrh 10// Chip should have been deselected before Reset is de-asserted [ns]
`define t_pw_typ 11000 //Page Write cycle time (256 bytes) (typical) [ns]
`define t_pw_max 23000 //Page Write cycle time (256 bytes) (max) [ns]
`define t_pp_256_typ 800 //Page Program cycle time (256 bytes) (typical) [ns]
`define t_pp_256_max 3000 //Page Program cycle time (256 bytes) (max) [ns]
`define t_pp_1_typ 3.125 //Page Program cycle time (1 bytes) (typical) [ns]
`define t_pp_1_max 3000 //Page Program cycle time (1 bytes) (max) [ns]
`define t_pe_typ 10000 //Page Erase cycle time (typical) [ns]
`define t_pe_max 20000 //Page Erase cycle time (max) [ns]
`define t_se_typ 1e9 //Sector Erase cycle time (typical) [ns]
`define t_se_max 5e9//Sector Erase cycle time (max) [ns]
