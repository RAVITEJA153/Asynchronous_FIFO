`timescale 1ns / 1ps
`timescale 1ns / 1ps


module  asynch_fifo (out, wr_full, rd_empty,
rd_clk, wr_clk, reset);

parameter WIDTH = 8;
parameter ptr = 4;
output [WIDTH-1 : 0] out;
output wr_full;
output rd_empty;
wire [WIDTH-1 : 0] data_in;
input rd_clk, wr_clk;
input reset;

reg [ptr : 0] rd_ptr, rd_sync_1, rd_sync_2;
reg [ptr : 0] wr_ptr, wr_sync_1, wr_sync_2;
wire [ptr:0] rd_ptr_g,wr_ptr_g;

parameter DEPTH = 1 << ptr;

reg [WIDTH-1 : 0] mem [DEPTH-1 : 0];

wire [ptr : 0] rd_ptr_sync;
wire [ptr: 0] wr_ptr_sync;
reg full,empty;
reg [7:0] tr_ptr;

//--write logic--//

always @(posedge wr_clk or posedge reset) begin
if (reset) begin
wr_ptr <= 0;
tr_ptr<=0;
end
else if (full == 1'b0) begin
wr_ptr <= wr_ptr + 1;
tr_ptr<=tr_ptr+1;
mem[wr_ptr[ptr-1 : 0]] <= data_in;
end
end

send s(tr_ptr,data_in);

//--read ptr synchronizer controlled by write clk--//

always @(posedge wr_clk) begin
rd_sync_1 <= rd_ptr_g;
rd_sync_2 <= rd_sync_1;
end

//--read logic--//

always @(posedge rd_clk or posedge reset) begin
if (reset) begin
rd_ptr <= 0;
end
else if (empty == 1'b0) begin
rd_ptr <= rd_ptr + 1;
end
end

//--write ptr synchronizer controled by read clk--//

always @(posedge rd_clk) begin
wr_sync_1 <= wr_ptr_g;
wr_sync_2 <= wr_sync_1;
end

//--cmbt logic--//
//--Binary ptr--//

always @(*)
begin
if({~wr_ptr[ptr],wr_ptr[ptr-1:0]}==rd_ptr_sync)
full = 1;
else
full = 0;
end


always @(*)
begin
if(wr_ptr_sync==rd_ptr)
empty = 1;
else
empty = 0;
end

assign out = mem[rd_ptr[ptr-1 : 0]];


//--binary code to gray code--//

assign wr_ptr_g = wr_ptr ^ (wr_ptr >> 1);
assign rd_ptr_g = rd_ptr ^ (rd_ptr >> 1);

//--gray code to binary code--//

assign wr_ptr_sync[4]=wr_sync_2[4];
assign wr_ptr_sync[3]=wr_sync_2[3] ^ wr_ptr_sync[4];
assign wr_ptr_sync[2]=wr_sync_2[2] ^ wr_ptr_sync[3];
assign wr_ptr_sync[1]=wr_sync_2[1] ^ wr_ptr_sync[2];
assign wr_ptr_sync[0]=wr_sync_2[0] ^ wr_ptr_sync[1];


assign rd_ptr_sync[4]=rd_sync_2[4];
assign rd_ptr_sync[3]=rd_sync_2[3] ^ rd_ptr_sync[4];
assign rd_ptr_sync[2]=rd_sync_2[2] ^ rd_ptr_sync[3];
assign rd_ptr_sync[1]=rd_sync_2[1] ^ rd_ptr_sync[2];
assign rd_ptr_sync[0]=rd_sync_2[0] ^ rd_ptr_sync[1];

assign wr_full = full;
assign rd_empty = empty;

endmodule

module send(wr_ptr,out);

output [7:0] out;
input [7:0] wr_ptr;
reg [7:0] input_rom [127:0];
integer i;
initial begin

for(i=0;i<128;i=i+1)
input_rom[i] = i+10;
end

assign out = input_rom[wr_ptr];

endmodule
