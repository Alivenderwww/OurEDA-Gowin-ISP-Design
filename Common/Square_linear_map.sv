module Square_linear_map #(
    parameter DATA_WIDTH = 8  //can't change
)(
    input wire clk,
    input wire reset,
    input wire en,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH-1:0] k_x,
    input wire [DATA_WIDTH-1:0] k_y,
    output reg [DATA_WIDTH-1:0] q
);

// q = din * k_x / k_y;

reg [2*DATA_WIDTH-1:0] dividend;
reg [DATA_WIDTH-1:0] divisor;
wire [2*DATA_WIDTH-1:0] quotient;

reg [2*DATA_WIDTH-1:0] din_0;
reg [DATA_WIDTH-1:0] k_x_0, k_y_0;

always @(posedge clk) begin
    if(reset) begin
        dividend <= 0;
        divisor <= 0;
        din_0 <= 0;
        k_x_0 <= 0;
        k_y_0 <= 0;
        q <= 0;
    end else begin
        //latency 1
        din_0 <= din * k_y;
        k_x_0 <= k_x;
        k_y_0 <= k_y;
        //latency 2
        if(en) begin
            dividend <= din_0;
            divisor <= k_x_0;
        end else begin
            dividend <= din_0;
            divisor <= k_y_0;
        end
        //latency 3,4,5,6,7
        //latency 8
        q <= (|quotient[2*DATA_WIDTH-1:DATA_WIDTH])?(~0):(quotient[DATA_WIDTH-1:0]);
    end
end

Square_linear_div your_instance_name(
	.clk(clk), //input clk
	.rstn(~reset), //input rstn
	.dividend(dividend), //input [15:0] dividend
	.divisor(divisor), //input [7:0] divisor
	.quotient(quotient) //output [15:0] quotient
);


endmodule