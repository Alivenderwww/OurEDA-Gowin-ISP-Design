module HSV_Adjust #(
    parameter HSV_DEPTH = 8
) (
    input wire                     clk,  
    input wire                     reset, 

    input wire                     in_valid,
    input wire  [HSV_DEPTH - 1:0]  in_data[3],
    input wire  [7:0]              in_user,

    output wire                    out_valid,
    output reg  [HSV_DEPTH - 1:0]  out_data[3],
    output wire    [7:0]           out_user,

    input wire                     in_ready,
    output wire                    out_ready,

    input wire [15:0] isp_ctrl,
    input wire [15:0] isp_hue_offset,
    input wire [15:0] isp_sat_gain_loss,
    input wire [15:0] isp_val_gain_loss
);

localparam PIPILINE = 9;

reg [7:0] pipeline_user[PIPILINE];
reg [PIPILINE-1:0] pipeline_valid;
wire pipeline_running;
assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

//out_ready ：只要本模块可以接收数据就一直拉高
assign out_ready = pipeline_running;
//out_valid ：只要本模块可以发出数据就一直拉高
assign out_valid = pipeline_valid[PIPILINE-1];
assign out_user = pipeline_user[PIPILINE-1];

reg [7:0] hue_offset, sat_gain_n, sat_loss_n, val_gain_n, val_loss_n;
wire [HSV_DEPTH-1:0] out_sat, out_val;
wire [HSV_DEPTH-1:0] in_sat, in_val;
reg hue_en, sat_en, val_en;
assign in_sat = in_data[1];
assign in_val = in_data[0];
always @(posedge clk) begin
    hue_en <= isp_ctrl[0] & isp_ctrl[10] & isp_ctrl[11];
    sat_en <= isp_ctrl[0] & isp_ctrl[10] & isp_ctrl[12];
    val_en <= isp_ctrl[0] & isp_ctrl[10] & isp_ctrl[13];
    hue_offset <= (hue_en)?(isp_hue_offset[ 7:0]):(0);
    sat_gain_n <= {(8){1'b1}} - isp_sat_gain_loss[15:8];
    sat_loss_n <= {(8){1'b1}} - isp_sat_gain_loss[ 7:0];
    val_gain_n <= {(8){1'b1}} - isp_val_gain_loss[15:8];
    val_loss_n <= {(8){1'b1}} - isp_val_gain_loss[ 7:0];
end

reg [HSV_DEPTH-1:0] hue_cache[PIPILINE-1];

integer i;
always @(posedge clk) begin
  if(reset) begin
    for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
    pipeline_valid <= 0;
  end else if(pipeline_running) begin
    
    pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};
    for(i=1;i<PIPILINE;i=i+1) pipeline_user[i] <= (pipeline_valid[i-1])?(pipeline_user[i-1]):(pipeline_user[i]);
    for(i=1;i<PIPILINE-1;i=i+1) hue_cache[i] <= (pipeline_valid[i-1])?(hue_cache[i-1]):(hue_cache[i]);

    if(in_valid) begin
        pipeline_user[0] <= in_user;
        hue_cache[0] <= in_data[2] + hue_offset;
    end

    if(pipeline_valid[7]) begin
        out_data[2] <= hue_cache[PIPILINE-2];
        out_data[1] <= out_sat;
        out_data[0] <= out_val;
    end
  end
end

Square_linear_map #(
    .DATA_WIDTH(HSV_DEPTH)
)Sat_linear_adjust(
    .clk  (clk),
    .reset(reset),
    .en   (sat_en),
    .din  (in_sat),
    .k_x  (sat_gain_n),
    .k_y  (sat_loss_n),
    .q    (out_sat)
);

Square_linear_map #(
    .DATA_WIDTH(HSV_DEPTH)
)Val_linear_adjust(
    .clk  (clk),
    .reset(reset),
    .en   (val_en),
    .din  (in_val),
    .k_x  (val_gain_n),
    .k_y  (val_loss_n),
    .q    (out_val)
);

endmodule