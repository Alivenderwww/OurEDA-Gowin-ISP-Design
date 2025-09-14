module fifo_isp_adapter #(
    parameter DATA_WIDTH = 16
)(
    input wire reset,

	input wire camera_clk,
	input wire in_valid,
	input wire [DATA_WIDTH - 1:0] in_data,
	input wire in_fsync,
	input wire in_hsync,

	input wire isp_clk,
	output reg out_valid,
	output reg [DATA_WIDTH - 1:0] out_data,
    output reg [7:0] out_user
);

localparam GIVEUP_FRAME = 3;
reg [5:0] frame_count;
wire flag_frame_init_done;
assign flag_frame_init_done = (frame_count >= GIVEUP_FRAME);

reg in_valid_d0, in_fsync_d0, in_hsync_d0;
wire  in_fsync_pos, in_hsync_pos;
assign in_fsync_pos = in_fsync && !in_fsync_d0;
assign in_hsync_pos = in_hsync && !in_hsync_d0;
always @(posedge camera_clk) begin
    if(reset) in_fsync_d0 <= 0;
    else in_fsync_d0 <= in_fsync;
end
always @(posedge camera_clk) begin
    if(reset) in_hsync_d0 <= 0;
    else in_hsync_d0 <= in_hsync;
end

always @(posedge camera_clk) begin
    if(reset) frame_count <= 0;
    else if(in_fsync_pos && frame_count <= GIVEUP_FRAME - 1) frame_count <= frame_count + 1;
    else frame_count <= frame_count;
end

reg fstart, hstart;
reg fifo_in_valid;
reg [DATA_WIDTH-1:0] in_data_d0;
reg [23:0] fifo_in_data;

always @(posedge camera_clk) begin
    if(reset) begin
        hstart <= 0;
        fstart <= 0;
        fifo_in_valid <= 0;
        fifo_in_data <= 0;
        in_valid_d0 <= 0;
        in_data_d0 <= 0;
    end else begin
        if(in_valid) in_data_d0 <= in_data;
        else in_data_d0 <= in_data_d0;
        
        in_valid_d0 <= in_valid && ~in_fsync && in_hsync;
        
        if(in_fsync_pos) fstart <= 1;
        else if(in_valid_d0 && flag_frame_init_done) fstart <= 0;
        else fstart <= fstart;

        if(in_hsync_pos) hstart <= 1;
        else if(in_valid_d0 && flag_frame_init_done) hstart <= 0;
        else hstart <= hstart;

        if(in_valid_d0 && flag_frame_init_done) begin
            fifo_in_valid <= 1;
            fifo_in_data <= {{(24-1-1-DATA_WIDTH){1'b0}},fstart,hstart,in_data_d0};
        end else begin
            fifo_in_valid <= 0;
            fifo_in_data <= fifo_in_data;
        end
    end
end

reg fifo_rd_en;
wire real_fifo_rd_en;
wire fifo_empty;
wire [23:0] fifo_out_data;
assign real_fifo_rd_en = fifo_rd_en & (~fifo_empty);

always @(posedge isp_clk) begin
    if(reset) fifo_rd_en <= 0;
    else if(~fifo_empty) fifo_rd_en <= 1;
    else fifo_rd_en <= 0;
end

always @(posedge isp_clk) begin
    if(reset) begin
        out_valid <= 0;
        out_user <= 0;
        out_data <= 0;
    end else if(real_fifo_rd_en) begin
        out_valid <= 1;
        out_data <= fifo_out_data[DATA_WIDTH-1:0];
        out_user <= {6'b0,fifo_out_data[DATA_WIDTH+1],fifo_out_data[DATA_WIDTH]};
    end else begin
        out_valid <= 0;
        out_data <= out_data;
    end
end



Camera2ISP_fifo Camera2ISP_fifo_u(
	.Data(fifo_in_data), //input [23:0] Data
    .Reset(reset),
	.WrClk(camera_clk), //input WrClk
	.RdClk(isp_clk), //input RdClk
	.WrEn(fifo_in_valid), //input WrEn
	.RdEn(real_fifo_rd_en), //input RdEn
	.Q(fifo_out_data), //output [23:0] Q
	.Empty(fifo_empty), //output Empty
	.Full() //output Full
);

endmodule