module Crop #(
    parameter COLOR_DEPTH = 16
) (
    input wire clk,
    input wire reset,

    input wire [COLOR_DEPTH - 1:0] in_data [3],
    input wire [7:0] in_user,
    output reg [COLOR_DEPTH - 1:0] out_data [3],
    output wire [7:0] out_user,
    
    input wire in_valid,
    output reg out_valid,
    
    input wire in_ready,
    output wire out_ready,

    input wire [15:0] isp_ctrl        ,
    input wire [15:0] isp_in_pixel_x  ,
    input wire [15:0] isp_in_pixel_y  ,
    input wire [15:0] isp_out_offset_x,
    input wire [15:0] isp_out_offset_y,
    input wire [15:0] isp_out_pixel_x ,
    input wire [15:0] isp_out_pixel_y 
);

  reg Crop_enable, Crop_line_resolve;
  reg [15:0] in_x, in_y, offset_x, offset_y, out_x, out_y;
  always @(posedge clk) begin
    Crop_enable <= isp_ctrl[7] & isp_ctrl[0];
    Crop_line_resolve <= isp_ctrl[8];
    in_x     <= isp_in_pixel_x  ;
    in_y     <= isp_in_pixel_y  ;
    offset_x <= isp_out_offset_x;
    offset_y <= isp_out_offset_y;
    out_x    <= isp_out_pixel_x ;
    out_y    <= isp_out_pixel_y ;
  end

  wire in_fstart, in_hstart;
  reg out_fstart, out_hstart;
  assign in_fstart = in_user[1];
  assign in_hstart = in_user[0];

  localparam PIPELINE = 3;

  reg [7:0] pipeline_user[PIPELINE];
  reg [PIPELINE-1:0] pipeline_valid;
  wire pipeline_running;
  assign pipeline_running = in_ready | ~pipeline_valid[PIPELINE-1];

  reg [31:0] cnt_x, cnt_y, temp_x, temp_y;
  reg force_dis;
  reg [COLOR_DEPTH-1:0] data_cache0[3];
  reg [COLOR_DEPTH-1:0] data_cache1[3];

  //out_ready ：只要本模块可以接收数据就一直拉高
  assign out_ready = pipeline_running;
  //out_valid ：只要本模块可以发出数据就一直拉高
  assign out_valid = (pipeline_valid[PIPELINE-1] & (~Crop_enable | ~force_dis));
  assign out_user = (Crop_enable)?({pipeline_user[PIPELINE-1][7:2],out_fstart,out_hstart}):(pipeline_user[PIPELINE-1]);

  //分别表示当前像素: 显示；被裁掉；空。
  reg [1:0] flag_crop;
  localparam CROP_KEEP    = 1'b0,
             CROP_GIVE_UP = 1'b1;

  integer i;

  always @(posedge clk) begin
    if(reset) for(i=0;i<3;i=i+1) data_cache0[i] <= 0;
    else if(pipeline_running & in_valid) for(i=0;i<3;i++) data_cache0[i] <= in_data[i];
    else for(i=0;i<3;i=i+1) data_cache0[i] <= data_cache0[i];
  end

  always @(posedge clk) begin
    if(reset) for(i=0;i<3;i=i+1) data_cache1[i] <= 0;
    else if(pipeline_running & pipeline_valid[0]) for(i=0;i<3;i++) data_cache1[i] <= data_cache0[i];
    else for(i=0;i<3;i=i+1) data_cache1[i] <= data_cache1[i];
  end

  always @(posedge clk) begin
    if(reset) begin
      pipeline_valid <= 0;
      cnt_x <= 0;
      cnt_y <= 0;
      
      for(i=0;i<3;i=i+1) out_data[i] <= 0;
      flag_crop <= 0;
      force_dis <= 0;
      out_hstart <= 0;
      out_fstart <= 0;
      temp_x <= 0;
      temp_y <= 0;
      for(i=0;i<PIPELINE;i=i+1) pipeline_user[i] <= 0;
    end else if(pipeline_running) begin

      pipeline_valid <= {pipeline_valid[PIPELINE-2:0],in_valid};

      if(in_valid) begin //when 00
        pipeline_user[0] <= in_user[7:2];
        cnt_x <= (in_hstart)?(0):(cnt_x+1);
        if(Crop_line_resolve) cnt_y <= (in_hstart)?((in_fstart && cnt_y >= offset_y + out_y - 1)?(0):(cnt_y+1)):(cnt_y);
        else cnt_y <= (in_hstart)?((in_fstart)?(0):(cnt_y+1)):(cnt_y);
      end

      if(pipeline_valid[0]) begin //when 00
        pipeline_user[1] <= pipeline_user[0];
        temp_x <= cnt_x;
        temp_y <= cnt_y;
        if(cnt_x < offset_x || cnt_y < offset_y) flag_crop <= CROP_GIVE_UP;
        else if(cnt_x < offset_x + out_x && cnt_y < offset_y + out_y) flag_crop <= CROP_KEEP;
        else flag_crop <= CROP_GIVE_UP;
      end

      if(pipeline_valid[1]) begin
        pipeline_user[2] <= pipeline_user[1];
        for(i=0;i<3;i++) out_data[i] <= data_cache1[i];
        out_hstart <= (temp_x == offset_x) && (temp_y >= offset_y);
        out_fstart <= (temp_x == offset_x) && (temp_y == offset_y);
        case (flag_crop)
          CROP_KEEP    : force_dis <= 1'b0;
          CROP_GIVE_UP : force_dis <= 1'b1;
        endcase
      end
    end
  end


endmodule
