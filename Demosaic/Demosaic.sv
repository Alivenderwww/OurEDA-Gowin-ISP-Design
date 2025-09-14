module Demosaic #(
parameter WINDOW_LENGTH = 3,
parameter reg [ 4:0] DATA_WIDTH = 16       // 输入/输出数据位宽
)(
    input wire clk,
    input wire reset,
    
    input wire [DATA_WIDTH - 1:0] in_data [WINDOW_LENGTH*WINDOW_LENGTH],     // 数据输入线.第一列数据在[0],[1],[2]中
    input wire [7:0] in_user,
    output reg [DATA_WIDTH - 1:0] out_data [3],   // 数据输出线，3、2、1分别表示r、g、b
    output wire [7:0] out_user,
    
    input wire in_valid,
    output wire out_valid,
    
    input wire in_ready,
    output wire out_ready,

    input wire [15:0] isp_ctrl
);

  reg Demosaic_enable;
  reg [1:0] isp_raw_type;
  always @(posedge clk) begin
    Demosaic_enable <= isp_ctrl[3] & isp_ctrl[0];
    isp_raw_type <= isp_ctrl[6:5];
  end

  localparam DATA_NUM = WINDOW_LENGTH*WINDOW_LENGTH;
  localparam PIPILINE = 2;

  reg [PIPILINE-1:0] pipeline_valid;
  reg [7:0] pipeline_user[PIPILINE];
  wire pipeline_running;
  assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

  //out_ready ：只要本模块可以接收数据就一直拉高
  assign out_ready = pipeline_running;
  //out_valid ：只要本模块可以发出数据就一直拉高
  assign out_valid = pipeline_valid[PIPILINE-1];
  assign out_user = pipeline_user[PIPILINE-1];

  reg pos_x, pos_y;
  reg [DATA_WIDTH-1:0] red_cache[4], blue_cache[4], green_cache[4];
  reg [1:0] raw_type;

  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<4;i=i+1) red_cache[i] <= 0;
      for(i=0;i<4;i=i+1) blue_cache[i] <= 0;
      for(i=0;i<4;i=i+1) green_cache[i] <= 0;
      pipeline_valid <= 0;
      {out_data[2],out_data[1],out_data[0]}  <= 0;
      for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
      pos_x <= 0;
      pos_y <= 0;
    end else if(pipeline_running) begin

      pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};

      if(in_valid) begin
        pipeline_user[0] <= in_user;
        pos_x <= (in_user[0])?(0):(~pos_x);
        pos_y <= (in_user[0])?((in_user[1])?(0):(~pos_y)):(pos_y);

        red_cache[0] <= (in_data[3] >> 1) + (in_data[5] >> 1);
        red_cache[1] <= (in_data[0] >> 2) + (in_data[2] >> 2) + (in_data[6] >> 2) + (in_data[8] >> 2);
        red_cache[2] <= in_data[4];
        red_cache[3] <= (in_data[1] >> 1) + (in_data[7] >> 1);

        green_cache[0] <= in_data[4];
        green_cache[1] <= (in_data[1] >> 2) + (in_data[3] >> 2) + (in_data[5] >> 2) + (in_data[7] >> 2);
        green_cache[2] <= (in_data[1] >> 2) + (in_data[3] >> 2) + (in_data[5] >> 2) + (in_data[7] >> 2);
        green_cache[3] <= in_data[4];

        blue_cache[0] <= (in_data[1] >> 1) + (in_data[7] >> 1);
        blue_cache[1] <= in_data[4];
        blue_cache[2] <= (in_data[0] >> 2) + (in_data[2] >> 2) + (in_data[6] >> 2) + (in_data[8] >> 2);
        blue_cache[3] <= (in_data[3] >> 1) + (in_data[5] >> 1);
      end

      if(pipeline_valid[0]) begin
        pipeline_user[1] <= pipeline_user[0];
        out_data[2] <= (Demosaic_enable)?(red_cache[raw_type]  ):(red_cache[2]  );
        out_data[1] <= (Demosaic_enable)?(green_cache[raw_type]):(green_cache[0]);
        out_data[0] <= (Demosaic_enable)?(blue_cache[raw_type] ):(blue_cache[1] );
      end

    end
  end

  //  0:g r g   1:r g r   2:b g b   3:g b g    0 3 6   窗口左右移，0<->1 2<->3
  //    b g b     g b g     g r g     r g r    1 4 7   窗口上下移，0<->2 1<->3
  //    g r g     r g r     b g b     g b g    2 5 8

  always @(*) begin
    case (isp_raw_type) //已经处理完偏移导致的RAW_TYPE偏移
      2'b00: raw_type = {~pos_y, ~pos_x};
      2'b01: raw_type = {~pos_y,  pos_x};
      2'b10: raw_type = { pos_y, ~pos_x};
      2'b11: raw_type = { pos_y,  pos_x};
    endcase
  end
endmodule

