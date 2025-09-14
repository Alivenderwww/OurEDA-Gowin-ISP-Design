module frame_size_detect (
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire hstart,
    input wire fstart,

    input wire [15:0] h_pixel,
    input wire [15:0] v_pixel,

    output wire h_pixel_correct,
    output wire v_pixel_correct
);

reg [15:0] h_pixel_cnt, v_pixel_cnt;
reg [3:0] h_pixel_match_times, v_pixel_match_times;
assign h_pixel_correct = (h_pixel_match_times == 4'hF);
assign v_pixel_correct = (v_pixel_match_times == 4'hF);

always @(posedge clk) begin
    if(reset) h_pixel_cnt <= 0;
    else if(hstart & in_valid) h_pixel_cnt <= 0;
    else if(in_valid) h_pixel_cnt <= h_pixel_cnt + 1;
    else h_pixel_cnt <= h_pixel_cnt;
end

always @(posedge clk) begin
    if(reset) h_pixel_match_times <= 0;
    else if(hstart&in_valid) begin
        if(h_pixel_cnt == h_pixel - 1) h_pixel_match_times <= (h_pixel_match_times == 4'hF)?(h_pixel_match_times):(h_pixel_match_times + 1);
        else h_pixel_match_times <= 0;
    end else h_pixel_match_times <= h_pixel_match_times;
end

always @(posedge clk) begin
    if(reset) v_pixel_cnt <= 0;
    else if(fstart & in_valid) v_pixel_cnt <= 0;
    else if(hstart & in_valid) v_pixel_cnt <= v_pixel_cnt + 1;
    else v_pixel_cnt <= v_pixel_cnt;
end

always @(posedge clk) begin
    if(reset) v_pixel_match_times <= 0;
    else if(fstart & in_valid) begin
        if(v_pixel_cnt == v_pixel - 1) v_pixel_match_times <= (v_pixel_match_times == 4'hF)?(v_pixel_match_times):(v_pixel_match_times + 1);
        else v_pixel_match_times <= 0;
    end else v_pixel_match_times <= v_pixel_match_times;
end

    
endmodule