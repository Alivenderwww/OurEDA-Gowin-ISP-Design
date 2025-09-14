module Nature_Sat_Adjust #(
    parameter COLOR_DEPTH = 8
) (
    input wire                     clk,  
    input wire                     reset, 

    input wire                      in_valid,
    input wire  [COLOR_DEPTH - 1:0] in_data[3],
    input wire  [7:0]               in_user,

    output wire                     out_valid,
    output reg  [COLOR_DEPTH - 1:0] out_data[3],
    output wire    [7:0]            out_user,

    input wire                     in_ready,
    output wire                    out_ready,

    input wire [15:0] isp_ctrl,
    input wire [7:0] isp_Adjustment
);

reg [6:0] Adjustment;
reg posorneg;
always @(posedge clk) begin
    {posorneg,Adjustment} <= isp_Adjustment;
end

localparam PIPILINE = 4;

reg [7:0] pipeline_user[PIPILINE];
reg [PIPILINE-1:0] pipeline_valid;
wire pipeline_running;
assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

//out_ready ：只要本模块可以接收数据就一直拉高
assign out_ready = pipeline_running;
//out_valid ：只要本模块可以发出数据就一直拉高
assign out_valid = pipeline_valid[PIPILINE-1];
assign out_user = pipeline_user[PIPILINE-1];

reg [2*COLOR_DEPTH-1:0] Sum;
reg [COLOR_DEPTH-1:0] Max, Max0;
reg [COLOR_DEPTH-1:0] data_cache0[3];
reg [COLOR_DEPTH-1:0] data_cache1[3];
reg [COLOR_DEPTH-1:0] data_cache2[3];
reg [15:0] AmtVal;
reg [3*COLOR_DEPTH-1:0] AmtVal_cal[3];

integer i;
always @(posedge clk) begin
  if(reset) begin
    for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
    for(i=0;i<3;i=i+1) data_cache0[i] <= 0;
    for(i=0;i<3;i=i+1) data_cache1[i] <= 0;
    for(i=0;i<3;i=i+1) data_cache2[i] <= 0;
    for(i=0;i<3;i=i+1) AmtVal_cal[i] <= 0;
    pipeline_valid <= 0;
    Sum <= 0;
    Max <= 0;
    Max0 <= 0;
    AmtVal <= 0;

  end else if(pipeline_running) begin
    
    pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};
    for(i=1;i<PIPILINE;i=i+1) pipeline_user[i] <= (pipeline_valid[i-1])?(pipeline_user[i-1]):(pipeline_user[i]);

    if(in_valid) begin
        pipeline_user[0] <= in_user;
        for(i=0;i<3;i=i+1) data_cache0[i] <= in_data[i];
        Sum <= (in_data[2] + in_data[1] + in_data[1] + in_data[0]);
        if(in_data[2] > in_data[1]) begin
            if(in_data[2] > in_data[0]) Max <= in_data[2];
            else Max <= in_data[0];
        end else if(in_data[1] > in_data[0]) Max <= in_data[1];
        else Max <= in_data[0];
    end

    if(pipeline_valid[0]) begin
        for(i=0;i<3;i=i+1) data_cache1[i] <= data_cache0[i];
        Max0 <= Max;
        AmtVal <= (Max - (Sum>>2)) * Adjustment;
    end

    if(pipeline_valid[1]) begin
        for(i=0;i<3;i=i+1) data_cache2[i] <= data_cache1[i];
        for(i=0;i<3;i=i+1) AmtVal_cal[i] <= (((Max0 - data_cache1[i]) * AmtVal) >> 14);
    end

    if(pipeline_valid[2]) begin
        for(i=0;i<3;i=i+1) if(data_cache1[i] == Max0) out_data[i] <= data_cache2[i];
        else if(posorneg) out_data[i] <= data_cache2[i] + AmtVal_cal[i];
        else out_data[i] <= data_cache2[i] - AmtVal_cal[i];
    end
  end
end



endmodule