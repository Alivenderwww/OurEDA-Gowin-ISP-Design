module AWB_Gray_World #(
parameter reg [ 4:0] DATA_WIDTH = 16        // 输入/输出数据位宽
)(
    input wire clk,
    input wire reset,
    
    input wire [DATA_WIDTH - 1:0] in_data,
    input wire [7:0] in_user,
    output reg [DATA_WIDTH - 1:0] out_data,
    output wire [7:0] out_user,
    
    input wire in_valid,
    output wire out_valid,
    
    input wire in_ready,
    output wire out_ready,

    input wire [15:0] isp_ctrl
);

  localparam GIVE_UP_ACC = 0;
  localparam PIPILINE = 25;

  reg AWB_Gray_World_enable;
  reg [1:0] isp_raw_type;
  always @(posedge clk) begin
    AWB_Gray_World_enable <= isp_ctrl[9] & isp_ctrl[0];
    isp_raw_type  <= isp_ctrl[6:5];
  end

  reg [DATA_WIDTH-1:0] data_cache0, data_cache1;
  reg [7:0] pipeline_user[PIPILINE];
  reg [PIPILINE-1:0] pipeline_valid;
  wire pipeline_running;
  assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

  //out_ready ：只要本模块可以接收数据就一直拉高
  assign out_ready = pipeline_running;
  //out_valid ：只要本模块可以发出数据就一直拉高
  assign out_valid = pipeline_valid[PIPILINE-1];
  assign out_user = pipeline_user[PIPILINE-1];

  reg pos_x, pos_y;
  reg [1:0] raw_type;

  reg [12+12+DATA_WIDTH-1:0] sum_r, sum_g, sum_b;
  reg [12+12+DATA_WIDTH-GIVE_UP_ACC-1:0] avg_r, avg_g, avg_b, avg_divisor;
  reg [12+12+DATA_WIDTH-GIVE_UP_ACC+1:0] avg_divisor_3multi;
  reg [12+12+DATA_WIDTH-GIVE_UP_ACC+1:0] avg_gray;
  reg [12+12+2*DATA_WIDTH-GIVE_UP_ACC+1:0] data_cache_cal0;
  reg [12+12+2*DATA_WIDTH-GIVE_UP_ACC+1:0] dividend;
  reg [12+12+DATA_WIDTH-GIVE_UP_ACC+1:0] divisor;
  wire [12+12+2*DATA_WIDTH-GIVE_UP_ACC+1:0] quotient;

  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
      pipeline_valid <= 0;
      out_data <= 0;
      pos_x <= 0;
      pos_y <= 0;
      {sum_r,sum_g,sum_b} <= 0;
      {avg_r,avg_g,avg_b} <= 0;
      avg_divisor <= 0;
      data_cache0 <= 0; data_cache1 <= 0;
      data_cache_cal0<= 0;
      avg_gray <= 0;
      avg_divisor_3multi <= 0;
      dividend <= 0;
      divisor <= 0;
    end else if(pipeline_running) begin

      pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};
      for(i=1;i<PIPILINE;i=i+1) pipeline_user[i] <= (pipeline_valid[i-1])?(pipeline_user[i-1]):(pipeline_user[i]);

      if(in_valid) begin
        data_cache0 <= in_data;
        pipeline_user[0] <= in_user;
        pos_x <= (in_user[0])?(0):(~pos_x);
        pos_y <= (in_user[0])?((in_user[1])?(0):(~pos_y)):(pos_y);
      end

      if(pipeline_valid[0]) begin
        data_cache1 <= data_cache0;
        if(pipeline_user[0][1]) begin
            avg_r <= sum_r >> GIVE_UP_ACC;
            avg_g <= sum_g >> (GIVE_UP_ACC + 1);
            avg_b <= sum_b >> GIVE_UP_ACC;
            avg_gray <= (sum_r + (sum_g>>1) + sum_b) >> GIVE_UP_ACC;
            case (raw_type)
                2'b00: begin sum_g <= data_cache0; sum_r <= 0; sum_b <= 0; avg_divisor <= sum_g >> (GIVE_UP_ACC + 1); end
                2'b01: begin sum_r <= data_cache0; sum_g <= 0; sum_b <= 0; avg_divisor <= sum_r >> GIVE_UP_ACC; end
                2'b10: begin sum_b <= data_cache0; sum_g <= 0; sum_r <= 0; avg_divisor <= sum_b >> GIVE_UP_ACC; end
                2'b11: begin sum_g <= data_cache0; sum_r <= 0; sum_b <= 0; avg_divisor <= sum_g >> (GIVE_UP_ACC + 1); end
            endcase
        end else begin
            case (raw_type)
                2'b00: begin sum_g <= sum_g + data_cache0; avg_divisor <= avg_g; end
                2'b01: begin sum_r <= sum_r + data_cache0; avg_divisor <= avg_r; end
                2'b10: begin sum_b <= sum_b + data_cache0; avg_divisor <= avg_b; end
                2'b11: begin sum_g <= sum_g + data_cache0; avg_divisor <= avg_g; end
            endcase
        end
      end

      if(pipeline_valid[1]) begin
        if(AWB_Gray_World_enable) begin
            data_cache_cal0 <= data_cache1 * avg_gray;
            avg_divisor_3multi<= avg_divisor * 3;
        end else begin
            data_cache_cal0<= data_cache1;
            avg_divisor_3multi<= 1;
        end
      end

      if(pipeline_valid[2]) begin
        dividend <= data_cache_cal0;
        divisor <= avg_divisor_3multi;
      end
      //WAIT 20...
      if(pipeline_valid[23]) begin //TAKE OUT DATA
        out_data <= (quotient >= {(DATA_WIDTH){1'b1}})?(~0):(quotient[DATA_WIDTH-1:0]);
      end
    end
  end

  /*
    0:g 1:r 2:b 3:g 
  */

  always @(posedge clk) begin
      case (isp_raw_type)
        2'b00: raw_type = { pos_y,  pos_x};
        2'b01: raw_type = { pos_y, ~pos_x};
        2'b10: raw_type = {~pos_y,  pos_x};
        2'b11: raw_type = {~pos_y, ~pos_x};
      endcase
  end

  //注意 该除法器模块按照DATA_WIDTH=8,GIVE_UP_ACC=0配置的位宽,latency=20,若顶层更改了DATA_WIDTH,需要重新在高云EDA里配置参数生成模块
	AWB_Integer_Division AWB_Integer_Division_inst(
		.clk(clk), //input clk
		.rstn(~reset), //input rstn
		.dividend(dividend), //input [4410] dividend
		.divisor(divisor), //input [3330] divisor
		.quotient(quotient) //output [4410] quotient
	);

endmodule

