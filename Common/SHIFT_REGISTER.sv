//RAM-BASED移位寄存器
//最大移位量4096,即一行像素个数最多4096个
module SHIFT_REGISTER #(
parameter reg [ 4:0] DATA_WIDTH = 16,       // 输入/输出数据位宽
parameter IFOUTIMME = 1'b0 //此项为0时，直至RAM存满IMAGE_WIDTH后再输出valid，为1时立即输出valid，无论是否存满
)(
    // 基本信号
    input wire clk,
    input wire reset,
    //  数据线
    input wire [DATA_WIDTH - 1:0] in_data,
    input wire [7:0] in_user, //in_user[0]是hstart, 行开始标志位, 用于给SHIFT_REGISTER判断输出与输入data的addr距离
    output wire [DATA_WIDTH - 1:0] out_data,
    output wire [7:0] out_user,
    //  有效信号
    input wire in_valid,    // 上一模块输出数据有效
    output wire out_valid    // 当前模块输出数据有效
);

reg [11:0] addr_a, addr_b;
wire cea, ceb;
reg fulldone;

reg in_valid_temp0, in_valid_temp1;
always @(posedge clk) in_valid_temp0 <= in_valid && (fulldone || IFOUTIMME);
always @(posedge clk) in_valid_temp1 <= in_valid_temp0;

assign cea = in_valid;
assign ceb = in_valid_temp0;
assign out_valid = in_valid_temp1;

wire hstart;
assign hstart = in_user[0];
reg [15:0] wr_rd_distance_cnt;
always @(posedge clk) begin
  if(reset) begin
    addr_a <= ~0;
    addr_b <= 0;
    wr_rd_distance_cnt <= 0;
  end else if(cea) begin
    addr_a <= addr_a + 1;
    if(hstart) begin
      wr_rd_distance_cnt <= 0;
      addr_b <= addr_a + 1 - (wr_rd_distance_cnt + 2);
    end else begin
      addr_b <= addr_b + 1;
      wr_rd_distance_cnt <= wr_rd_distance_cnt + 1;
    end
  end else begin
    addr_a <= addr_a;
    addr_b <= addr_b;
    wr_rd_distance_cnt <= wr_rd_distance_cnt;
  end
end

always @(posedge clk) begin
  if(reset) fulldone <= 0;
  else if(cea && hstart && (addr_b != 0)) fulldone <= 1;
  else fulldone <= fulldone;
end

wire [15:0] din, dout;
assign din = {{(16-DATA_WIDTH){1'b0}},in_data};
assign out_data = dout[DATA_WIDTH-1:0];
// Single-Double-Port-BRAM-IP Bypass Normal
Gowin_SDPB Gowin_SDPB_inst(
  .clka(clk), //input clka
  .clkb(clk), //input clkb
  .reset(reset), //input reset

  .cea(cea), //input cea
  .ceb(ceb), //input ceb

  .ada(addr_a), //input [11:0] ada
  .adb(addr_b), //input [11:0] adb

  .din(din), //input [15:0] din
  .dout(dout), //output [15:0] dout

  .oce(1) //input oce
);

// Single-Double-Port-BRAM-IP Bypass Normal
Gowin_SDPB_USER Gowin_SDPB_user_inst(
  .clka(clk), //input clka
  .clkb(clk), //input clkb
  .reset(reset), //input reset

  .cea(cea), //input cea
  .ceb(ceb), //input ceb

  .ada(addr_a), //input [11:0] ada
  .adb(addr_b), //input [11:0] adb

  .din(in_user), //input [7:0] din
  .dout(out_user), //output [7:0] dout

  .oce(1) //input oce
);

endmodule

