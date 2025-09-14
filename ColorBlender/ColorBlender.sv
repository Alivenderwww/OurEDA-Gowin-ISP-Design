`timescale 1ns / 1ps

// 三通道图像合成一个RGB图像
module ColorBlender #(
    parameter reg [4:0] DATA_WIDTH = 12,  // 输入图像的色深
    parameter reg [4:0] OUT_DEPTH = 8    // 输出图像的色深
) (
    input wire clk,
    input wire reset,
    
    input wire [DATA_WIDTH - 1:0] in_data [3],
    input wire [7:0] in_user,
    output reg [OUT_DEPTH - 1:0] out_data [3],
    output wire [7:0] out_user,
    
    input wire in_valid,
    output wire out_valid,
    
    input wire in_ready,
    output wire out_ready,

    // 颜色校正
    input wire [15:0] isp_ctrl  ,
    input wire [15:0] gain_red  ,
    input wire [15:0] gain_green,
    input wire [15:0] gain_blue 
);

  reg ColorBlender_enable;
  reg [15:0] gain_r, gain_g, gain_b;
  always @(posedge clk) begin
    ColorBlender_enable <= isp_ctrl[4] & isp_ctrl[0];
    gain_r <= gain_red;
    gain_g <= gain_green;
    gain_b <= gain_blue;
  end

  localparam PIPELINE = 4;

  reg [7:0] pipeline_user[PIPELINE];

  reg [PIPELINE-1:0] pipeline_valid;
  wire pipeline_flag;
  assign pipeline_flag = (pipeline_valid[PIPELINE-1] == 0) | (in_ready);

  //out_ready ：只要本模块可以接收数据就一直拉高
  assign out_ready = pipeline_flag;
  //out_valid ：只要本模块有数据要发送就一直拉高
  assign out_valid = pipeline_valid[PIPELINE-1];
  assign out_user = pipeline_user[PIPELINE-1];

  reg [32 - 1:0] data_cal0[3];
  reg [32 - 1:0] data_cal1[3];
  reg [32 - 1:0] data_cal2[3];

  integer i;
  always @(posedge clk) begin
    if(reset) begin
      pipeline_valid <= 0;
      for(i=0;i<3;i=i+1) data_cal0[i] <= 0;
      for(i=0;i<3;i=i+1) data_cal1[i] <= 0;
      for(i=0;i<3;i=i+1) data_cal2[i] <= 0;
      for(i=0;i<3;i=i+1) out_data[i] <= 0;
      for(i=0;i<PIPELINE;i=i+1) pipeline_user[i] <= 0;
    end else if(pipeline_flag) begin
      /*************   流水    ************/
      pipeline_valid <= {pipeline_valid[PIPELINE-2:0], in_valid};
      /************* 1:计算1   ************/
      if(in_valid) begin
        pipeline_user[0] <= in_user;
        data_cal0[0] <= (in_data[0]) << (8 - (DATA_WIDTH - OUT_DEPTH));
        data_cal0[1] <= (in_data[1]) << (8 - (DATA_WIDTH - OUT_DEPTH));
        data_cal0[2] <= (in_data[2]) << (8 - (DATA_WIDTH - OUT_DEPTH));
      end
      /************* 2:计算2   ************/
      if(pipeline_valid[0]) begin
        pipeline_user[1] <= pipeline_user[0];
        if(ColorBlender_enable) begin
          data_cal1[0] <= (data_cal0[0] * {16'b0, gain_b}) >> 16;
          data_cal1[1] <= (data_cal0[1] * {16'b0, gain_g}) >> 16;
          data_cal1[2] <= (data_cal0[2] * {16'b0, gain_r}) >> 16;
        end else begin
          data_cal1[0] <= data_cal0[0] >> 8;
          data_cal1[1] <= data_cal0[1] >> 8;
          data_cal1[2] <= data_cal0[2] >> 8;
        end
      end
      /************* 3:计算3   ************/
      if(pipeline_valid[1]) begin
        pipeline_user[2] <= pipeline_user[1];
        data_cal2[0] <= (|data_cal1[0][31 : OUT_DEPTH]) ? {32{1'b1}} : data_cal1[0];
        data_cal2[1] <= (|data_cal1[1][31 : OUT_DEPTH]) ? {32{1'b1}} : data_cal1[1];
        data_cal2[2] <= (|data_cal1[2][31 : OUT_DEPTH]) ? {32{1'b1}} : data_cal1[2];
      end
      /************* 4:发送结果  ************/
      if(pipeline_valid[2]) begin 
        pipeline_user[3] <= pipeline_user[2];
        out_data[0] <= data_cal2[0][OUT_DEPTH-1:0];
        out_data[1] <= data_cal2[1][OUT_DEPTH-1:0];
        out_data[2] <= data_cal2[2][OUT_DEPTH-1:0];
      end
    end
  end

endmodule
