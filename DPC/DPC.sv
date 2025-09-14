module DPC #(
parameter reg [ 4:0] DATA_WIDTH = 16        // 输入/输出数据位宽
)(
    input wire clk,
    input wire reset,
    
    input wire [DATA_WIDTH - 1:0] in_data [5*5],
    input wire [7:0] in_user,
    output reg [DATA_WIDTH - 1:0] out_data,
    output wire [7:0] out_user,
    
    input wire in_valid,
    output wire out_valid,
    
    input wire in_ready,
    output wire out_ready,

    input wire [15:0] isp_ctrl,
    input wire [15:0] threshold
);

  localparam WINDOW_LENGTH = 5;
  localparam DATA_NUM = WINDOW_LENGTH*WINDOW_LENGTH;
  localparam EXPAND_BITS = 1;
  localparam PIPILINE = 9;

  reg DPC_enable, label_enable;
  reg [1:0] isp_raw_type;
  reg signed [15:0] dpc_threshold;
  always @(posedge clk) begin
    DPC_enable    <= isp_ctrl[1] & isp_ctrl[0];
    label_enable  <= isp_ctrl[2];
    isp_raw_type  <= isp_ctrl[6:5];
    dpc_threshold <= threshold;
  end

  reg [7:0] pipeline_user[PIPILINE];
  reg [PIPILINE-1:0] pipeline_valid;
  wire pipeline_running;
  assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

  //out_ready ：只要本模块可以接收数据就一直拉高
  assign out_ready = pipeline_running;
  //out_valid ：只要本模块可以发出数据就一直拉高
  assign out_valid = pipeline_valid[PIPILINE-1];
  assign out_user = pipeline_user[PIPILINE-1];

  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] data_cache[DATA_NUM];  // 缓存颜色数据，行列nxn
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] data_cache0[DATA_NUM];  // 缓存颜色数据，行列nxn
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] channel_cache[9];  // 缓存颜色通道数据，channel_cache[4]就是中心像素点
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] channel_cache0,channel_cache1,channel_cache2,channel_cache3,channel_cache4;  // 缓存中心像素点的颜色数据
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] grad_h_cache[3], grad_v_cache[3], grad_i_cache[3], grad_t_cache[3];
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] grad_h_cache0[3], grad_v_cache0[3], grad_i_cache0[3], grad_t_cache0[3];
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] grad_h_cache1[3], grad_v_cache1[3], grad_i_cache1[3], grad_t_cache1[3];
  reg signed [DATA_WIDTH-1+EXPAND_BITS+2:0] grad_cache_excute[4];
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] grad_cache_center[4];
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] channel_cache_correct[4], channel_cache_correct1[4], channel_cache_correct2[4];
  reg signed [DATA_WIDTH-1+EXPAND_BITS+EXPAND_BITS:0] channel_cache_correct0[4];
  reg signed [DATA_WIDTH-1+EXPAND_BITS:0] grad_median_cache[4];
  reg [1:0] flag_which_dict, dic2;
  reg [DATA_WIDTH-1:0] channel_cache_correct_final;
  reg flag_if_need_corection;
  reg pos_x, pos_y;
  reg [1:0] raw_type;
  /*
      -------h
      |\  i
      | \/ 
      | /\
      |/  \
      v    t
  */

  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
      for(i=0;i<DATA_NUM;i=i+1) data_cache[i] <= 0;
      for(i=0;i<DATA_NUM;i=i+1) data_cache0[i] <= 0;
      for(i=0;i<9;i=i+1) channel_cache[i] <= 0;
      channel_cache0 <= 0;
      channel_cache1 <= 0;
      channel_cache2 <= 0;
      channel_cache3 <= 0;
      channel_cache4 <= 0;
      channel_cache_correct_final <= 0;
      for(i=0;i<3;i=i+1) grad_h_cache[i] <= 0; for(i=0;i<3;i=i+1) grad_h_cache0[i] <= 0; for(i=0;i<3;i=i+1) grad_h_cache1[i] <= 0; for(i=0;i<3;i=i+1);
      for(i=0;i<3;i=i+1) grad_v_cache[i] <= 0; for(i=0;i<3;i=i+1) grad_v_cache0[i] <= 0; for(i=0;i<3;i=i+1) grad_v_cache1[i] <= 0; for(i=0;i<3;i=i+1);
      for(i=0;i<3;i=i+1) grad_i_cache[i] <= 0; for(i=0;i<3;i=i+1) grad_i_cache0[i] <= 0; for(i=0;i<3;i=i+1) grad_i_cache1[i] <= 0; for(i=0;i<3;i=i+1);
      for(i=0;i<3;i=i+1) grad_t_cache[i] <= 0; for(i=0;i<3;i=i+1) grad_t_cache0[i] <= 0; for(i=0;i<3;i=i+1) grad_t_cache1[i] <= 0; for(i=0;i<3;i=i+1);
      for(i=0;i<3;i=i+1) grad_median_cache[i] <= 0;
      for(i=0;i<4;i=i+1) grad_cache_excute[i] <= 0;
      for(i=0;i<4;i=i+1) grad_cache_center[i] <= 0;
      flag_which_dict <= 0;
      flag_if_need_corection <= 0;
      for(i=0;i<4;i=i+1) channel_cache_correct[i] <= 0; for(i=0;i<4;i=i+1) channel_cache_correct1[i] <= 0;
      for(i=0;i<4;i=i+1) channel_cache_correct0[i] <= 0;for(i=0;i<4;i=i+1) channel_cache_correct2[i] <= 0;
      
      pipeline_valid <= 0;
      out_data <= 0;
      pos_x <= 0;
      pos_y <= 0;
    end else if(pipeline_running) begin

      pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};

      if(in_valid) begin
        for(i=0;i<DATA_NUM;i=i+1) data_cache0[i] <= {{(EXPAND_BITS){1'b0}},in_data[i]};
        pipeline_user[0] <= in_user;
        pos_x <= (in_user[0])?(0):(~pos_x);
        pos_y <= (in_user[0])?((in_user[1])?(0):(~pos_y)):(pos_y);
      end

      if(pipeline_valid[0]) begin
        for(i=0;i<DATA_NUM;i=i+1) data_cache[i] <= data_cache0[i];
        pipeline_user[1] <= pipeline_user[0];
        case (isp_raw_type)
          2'b00: raw_type <= { pos_y,  pos_x};
          2'b01: raw_type <= { pos_y, ~pos_x};
          2'b10: raw_type <= {~pos_y,  pos_x};
          2'b11: raw_type <= {~pos_y, ~pos_x};
        endcase
      end

      if(pipeline_valid[1]) begin
        pipeline_user[2] <= pipeline_user[1];
        case (raw_type)
          1,2: begin
            channel_cache[0] <= data_cache[00];
            channel_cache[1] <= data_cache[10];
            channel_cache[2] <= data_cache[20];
            channel_cache[3] <= data_cache[02];
            channel_cache[4] <= data_cache[12];
            channel_cache[5] <= data_cache[22];
            channel_cache[6] <= data_cache[04];
            channel_cache[7] <= data_cache[14];
            channel_cache[8] <= data_cache[24];
          end
          0,3: begin
            channel_cache[0] <= data_cache[02];
            channel_cache[1] <= data_cache[06];
            channel_cache[2] <= data_cache[10];
            channel_cache[3] <= data_cache[08];
            channel_cache[4] <= data_cache[12];
            channel_cache[5] <= data_cache[16];
            channel_cache[6] <= data_cache[14];
            channel_cache[7] <= data_cache[18];
            channel_cache[8] <= data_cache[22];
          end
        endcase
      end

      if(pipeline_valid[2]) begin //计算梯度，同时开始校正后数据的部分计算
            pipeline_user[3] <= pipeline_user[2];
            channel_cache0 <= channel_cache[4];

            grad_h_cache[0] <= channel_cache[0]/2 + channel_cache[2]/2 - channel_cache[1];
            grad_h_cache[1] <= channel_cache[3]/2 + channel_cache[5]/2 - channel_cache[4];
            grad_h_cache[2] <= channel_cache[6]/2 + channel_cache[8]/2 - channel_cache[7];
            grad_v_cache[0] <= channel_cache[0]/2 + channel_cache[6]/2 - channel_cache[3];
            grad_v_cache[1] <= channel_cache[1]/2 + channel_cache[7]/2 - channel_cache[4];
            grad_v_cache[2] <= channel_cache[2]/2 + channel_cache[8]/2 - channel_cache[5];
            grad_i_cache[0] <= channel_cache[1]/2 - channel_cache[3]/2;
            grad_i_cache[1] <= channel_cache[6]/2 + channel_cache[2]/2 - channel_cache[4];
            grad_i_cache[2] <= channel_cache[5]/2 - channel_cache[7]/2;
            grad_t_cache[0] <= channel_cache[1]/2 - channel_cache[5]/2;
            grad_t_cache[1] <= channel_cache[0]/2 + channel_cache[8]/2 - channel_cache[4];
            grad_t_cache[2] <= channel_cache[3]/2 - channel_cache[7]/2;

            channel_cache_correct[0] <= channel_cache[3]/2 + channel_cache[5]/2;
            channel_cache_correct[1] <= channel_cache[1]/2 + channel_cache[7]/2;
            channel_cache_correct[2] <= channel_cache[2]/2 + channel_cache[6]/2;
            channel_cache_correct[3] <= channel_cache[0]/2 + channel_cache[8]/2;
      end

      if(pipeline_valid[3]) begin //计算绝对值，同时完成校正后数据的计算
            pipeline_user[4] <= pipeline_user[3];
            channel_cache1 <= channel_cache0;

            for(i=0;i<3;i=i+1) grad_h_cache0[i] <= (grad_h_cache[i] < 0) ? (-grad_h_cache[i]) : (grad_h_cache[i]);
            for(i=0;i<3;i=i+1) grad_v_cache0[i] <= (grad_v_cache[i] < 0) ? (-grad_v_cache[i]) : (grad_v_cache[i]);
            for(i=0;i<3;i=i+1) grad_i_cache0[i] <= (grad_i_cache[i] < 0) ? (-grad_i_cache[i]) : (grad_i_cache[i]);
            for(i=0;i<3;i=i+1) grad_t_cache0[i] <= (grad_t_cache[i] < 0) ? (-grad_t_cache[i]) : (grad_t_cache[i]);
            channel_cache_correct0[0] <= channel_cache_correct[0] - grad_h_cache[0]/2 - grad_h_cache[2]/2;
            channel_cache_correct0[1] <= channel_cache_correct[1] - grad_v_cache[0]/2 - grad_v_cache[2]/2;
            channel_cache_correct0[2] <= channel_cache_correct[2] - grad_i_cache[0]/2 - grad_i_cache[2]/2;
            channel_cache_correct0[3] <= channel_cache_correct[3] - grad_t_cache[0]/2 - grad_t_cache[2]/2;
      end

      if(pipeline_valid[4]) begin //计算中位数
        pipeline_user[5] <= pipeline_user[4];
        channel_cache2 <= channel_cache1;
        for(i=0;i<4;i=i+1) channel_cache_correct1[i] <= (channel_cache_correct0[i] < 0) ? (0) : (channel_cache_correct0[i]);
        // for(i=0;i<4;i=i+1) channel_cache_correct1[i] <= channel_cache_correct0[i];
        for(i=0;i<3;i=i+1) grad_h_cache1[i] <= grad_h_cache0[i];
        for(i=0;i<3;i=i+1) grad_v_cache1[i] <= grad_v_cache0[i];
        for(i=0;i<3;i=i+1) grad_i_cache1[i] <= grad_i_cache0[i];
        for(i=0;i<3;i=i+1) grad_t_cache1[i] <= grad_t_cache0[i];

        grad_median_cache[0] <= MEDIAN(grad_h_cache0);
        grad_median_cache[1] <= MEDIAN(grad_v_cache0);
        grad_median_cache[2] <= MEDIAN(grad_i_cache0);
        grad_median_cache[3] <= MEDIAN(grad_t_cache0);
      end

      if(pipeline_valid[5]) begin //计算最小值，判断最小梯度方向
        pipeline_user[6] <= pipeline_user[5];
        channel_cache3 <= channel_cache2;
        for(i=0;i<4;i=i+1) channel_cache_correct2[i] <= channel_cache_correct1[i];

        grad_cache_center[0] <= grad_h_cache1[1];
        grad_cache_center[1] <= grad_v_cache1[1];
        grad_cache_center[2] <= grad_i_cache1[1];
        grad_cache_center[3] <= grad_t_cache1[1];
        grad_cache_excute[0] <= grad_h_cache1[0] + grad_h_cache1[2] + dpc_threshold;
        grad_cache_excute[1] <= grad_v_cache1[0] + grad_v_cache1[2] + dpc_threshold;
        grad_cache_excute[2] <= grad_i_cache1[0] + grad_i_cache1[2] + dpc_threshold;
        grad_cache_excute[3] <= grad_t_cache1[0] + grad_t_cache1[2] + dpc_threshold;

        flag_which_dict <= MIN(grad_median_cache);
      end

      if(pipeline_valid[6]) begin //在最小梯度方向上判断中心点是否是坏点
        pipeline_user[7] <= pipeline_user[6];
        dic2 <= flag_which_dict;
        channel_cache4 <= channel_cache3;
        channel_cache_correct_final <= channel_cache_correct2[flag_which_dict][DATA_WIDTH-1:0];
        case (flag_which_dict)
          2'b00, 2'b01: flag_if_need_corection <= (grad_cache_center[flag_which_dict] > grad_cache_excute[flag_which_dict]);
          2'b10, 2'b11: flag_if_need_corection <= (grad_cache_center[2] > grad_cache_excute[2]) && ((grad_cache_center[3] > grad_cache_excute[3]));
        endcase
      end

      if(pipeline_valid[7]) begin //如果是坏点，输出计算后的值；如果不是坏点，输出原值
        pipeline_user[8] <= pipeline_user[7];
        if(flag_if_need_corection && DPC_enable) begin
          if(label_enable) out_data <= ~0;
          else out_data <= channel_cache_correct_final;
        end else out_data <= channel_cache4;
      end
    end
  end

  function signed [DATA_WIDTH-1+EXPAND_BITS:0] MEDIAN;
    	input signed [DATA_WIDTH-1+EXPAND_BITS:0] inx[3];
  begin
      if((inx[0] >= inx[1] && inx[1] >= inx[2]) || (inx[2] >= inx[1] && inx[1] >= inx[0])) MEDIAN = inx[1];
      else if((inx[1] >= inx[0] && inx[0] >= inx[2]) || (inx[2] >= inx[0] && inx[0] >= inx[1])) MEDIAN = inx[0];
      else MEDIAN = inx[2];
  end
  endfunction

  function [1:0] MIN;
    	input signed [DATA_WIDTH-1+EXPAND_BITS:0] inx[4];
  begin
      if(inx[0] <= inx[1] && inx[0] <= inx[2] && inx[0] <= inx[3]) MIN = 2'b00;
      else if(inx[1] <= inx[2] && inx[1] <= inx[3]) MIN = 2'b01;
      else if(inx[2] <= inx[3]) MIN = 2'b10;
      else MIN = 2'b11;
  end
  endfunction

  /*
    00 05 10 15 20
    01 06 11 16 21      0 1 2
    02 07 12 17 22  ->  3 4 5
    03 08 13 18 23      6 7 8
    04 09 14 19 24

    rawtype==0: center is GREEN
    g r g r g      / / g / /
    b g b g b      / g / g /
    g r g r g  ->  g / G / g
    b g b g b      / g / g /
    g r g r g      / / g / /
    
    rawtype==1: center is RED
    r g r g r      r / r / r
    g b g b g      / / / / /
    r g r g r  ->  r / R / r
    g b g b g      / / / / /
    r g r g r      r / r / r
    
    rawtype==2: center is BLUE
    b g b g b      b / b / b
    g r g r g      / / / / /
    b g b g b  ->  b / B / b
    g r g r g      / / / / /
    b g b g b      b / b / b
    
    rawtype==3: center is GREEN
    g b g b g      / / g / /
    r g r g r      / g / g /
    g b g b g  ->  g / G / g
    r g r g r      / g / g /
    r g r g r      / / g / /


  */

endmodule

