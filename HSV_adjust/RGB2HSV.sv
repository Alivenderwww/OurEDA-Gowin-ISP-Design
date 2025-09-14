module RGB2HSV #(          //HSV: hue, saturation, value. (same as HSB(Brightness))
    parameter RGB_DEPTH = 8,
    parameter HSV_DEPTH = 8 //仅在HSV_DEPTH=8, RGB_DEPTH=8测试没问题
) (
    input wire                     clk,  
    input wire                     reset, 

    input wire                     in_valid,
    input wire  [RGB_DEPTH - 1:0]  in_data[3],
    input wire  [7:0]              in_user,

    output wire                    out_valid,
    output reg  [HSV_DEPTH - 1:0]  out_data[3],
    output wire    [7:0]           out_user,

    input wire                     in_ready,
    output wire                    out_ready
);

localparam PIPILINE = 10;

reg [RGB_DEPTH-1:0] data_cache0[3];
reg [7:0] pipeline_user[PIPILINE];
reg [PIPILINE-1:0] pipeline_valid;
wire pipeline_running;
assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

//out_ready ：只要本模块可以接收数据就一直拉高
assign out_ready = pipeline_running;
//out_valid ：只要本模块可以发出数据就一直拉高
assign out_valid = pipeline_valid[PIPILINE-1];
assign out_user = pipeline_user[PIPILINE-1];

localparam HUE_BASE  = (1 << HSV_DEPTH),
           HUE_BASE0 = ((HUE_BASE -         0)/6) + 0         + 1,//        0 - HUE_BASE0 is R-G-B zone
           HUE_BASE1 = ((HUE_BASE - HUE_BASE0)/5) + HUE_BASE0 + 1,//HUE_BASE0 - HUE_BASE1 is G-R-B zone
           HUE_BASE2 = ((HUE_BASE - HUE_BASE1)/4) + HUE_BASE1 + 1,//HUE_BASE1 - HUE_BASE2 is G-B-R zone
           HUE_BASE3 = ((HUE_BASE - HUE_BASE2)/3) + HUE_BASE2 + 1,//HUE_BASE2 - HUE_BASE3 is B-G-R zone
           HUE_BASE4 = ((HUE_BASE - HUE_BASE3)/2) + HUE_BASE3 + 1,//HUE_BASE3 - HUE_BASE4 is B-R-G zone
           HUE_BASE5 = ((HUE_BASE - HUE_BASE4)/1) + HUE_BASE4 + 1;//HUE_BASE4 - HUE_BASE5 is R-B-G zone

reg [RGB_DEPTH + HSV_DEPTH : 0] hue_dividend;
reg [RGB_DEPTH-1+3:0] hue_divisor;
wire [RGB_DEPTH + HSV_DEPTH : 0] hue_quotient;

reg [RGB_DEPTH+HSV_DEPTH-1:0] sat_dividend;
reg [RGB_DEPTH-1:0] sat_divisor;
wire [RGB_DEPTH+HSV_DEPTH-1:0] sat_quotient;

reg [RGB_DEPTH-1:0] Val_cal[PIPILINE-3];
reg [RGB_DEPTH-1:0] RGB_max, RGB_middle, RGB_min;
reg [RGB_DEPTH-1:0] RGB_middle_sub_min;
reg [RGB_DEPTH-1:0] RGB_max_sub_min;
reg [2:0] RGB_Compare_Size[PIPILINE-1];
localparam  Compare_RGB = 3'b000, //MAX -> MIN
            Compare_RBG = 3'b001,
            Compare_BGR = 3'b010,
            Compare_BRG = 3'b011,
            Compare_GRB = 3'b100,
            Compare_GBR = 3'b101;

integer i;
always @(posedge clk) begin
  if(reset) begin
    for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
    for(i=0;i<3;i=i+1) data_cache0[i] <= 0;
    for(i=0;i<3;i=i+1) out_data[i] <= 0;
    pipeline_valid <= 0;
  end else if(pipeline_running) begin
    
    pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};
    for(i=1;i<PIPILINE;i=i+1) pipeline_user[i] <= (pipeline_valid[i-1])?(pipeline_user[i-1]):(pipeline_user[i]);
    for(i=1;i<PIPILINE-1;i=i+1) RGB_Compare_Size[i] <= (pipeline_valid[i-1])?(RGB_Compare_Size[i-1]):(RGB_Compare_Size[i]);
    for(i=1;i<PIPILINE-3;i=i+1) Val_cal[i] <= (pipeline_valid[i+1])?(Val_cal[i-1]):(Val_cal[i]);

    if(in_valid) begin
        for(i=0;i<3;i=i+1) data_cache0[i] <= in_data[i];
        pipeline_user[0] <= in_user;
        if(in_data[2] >= in_data[1] && in_data[2] >= in_data[0]) begin//R>G, R>B, so R is max
            if(in_data[0] <= in_data[1]) RGB_Compare_Size[0] <= Compare_RGB;       //B is min
            else                         RGB_Compare_Size[0] <= Compare_RBG;       //G is min
        end else if(in_data[0] >= in_data[1]) begin //R not max,B>G,so G not max, so B is max
            if(in_data[2] <= in_data[1]) RGB_Compare_Size[0] <= Compare_BGR;       //R is min
            else                         RGB_Compare_Size[0] <= Compare_BRG;       //G is min
        end else begin                                    //R and B both not max, so G is max
            if(in_data[2] <= in_data[0]) RGB_Compare_Size[0] <= Compare_GBR;       //R is min
            else                         RGB_Compare_Size[0] <= Compare_GRB;       //B is min
        end
    end

    if(pipeline_valid[0]) begin
        case (RGB_Compare_Size[0])
            Compare_RGB: begin RGB_max <= data_cache0[2] ; RGB_middle <= data_cache0[1]; RGB_min <= data_cache0[0];end
            Compare_RBG: begin RGB_max <= data_cache0[2] ; RGB_middle <= data_cache0[0]; RGB_min <= data_cache0[1];end
            Compare_BGR: begin RGB_max <= data_cache0[0] ; RGB_middle <= data_cache0[1]; RGB_min <= data_cache0[2];end
            Compare_BRG: begin RGB_max <= data_cache0[0] ; RGB_middle <= data_cache0[2]; RGB_min <= data_cache0[1];end
            Compare_GRB: begin RGB_max <= data_cache0[1] ; RGB_middle <= data_cache0[2]; RGB_min <= data_cache0[0];end
            Compare_GBR: begin RGB_max <= data_cache0[1] ; RGB_middle <= data_cache0[0]; RGB_min <= data_cache0[2];end
            default:     begin RGB_max <= data_cache0[2] ; RGB_middle <= data_cache0[1]; RGB_min <= data_cache0[0];end
        endcase
    end

    if(pipeline_valid[1]) begin
        Val_cal[0] <= RGB_max;
        RGB_middle_sub_min <= RGB_middle - RGB_min;
        RGB_max_sub_min <= RGB_max - RGB_min;
    end

    if(pipeline_valid[2]) begin
        hue_dividend <= RGB_middle_sub_min << HSV_DEPTH;
        hue_divisor <= RGB_max_sub_min * 6;
        sat_dividend <= RGB_max_sub_min << HSV_DEPTH;
        sat_divisor <= Val_cal[0];
    end
    //WAIT 5...
    if(pipeline_valid[8]) begin
        case (RGB_Compare_Size[PIPILINE-2])
            Compare_RGB: out_data[2] <=         0 + hue_quotient;
            Compare_RBG: out_data[2] <=         0 - hue_quotient;
            Compare_BGR: out_data[2] <= HUE_BASE3 - hue_quotient;
            Compare_BRG: out_data[2] <= HUE_BASE3 + hue_quotient;
            Compare_GRB: out_data[2] <= HUE_BASE1 - hue_quotient;
            Compare_GBR: out_data[2] <= HUE_BASE1 + hue_quotient;
            default:     out_data[2] <=         0 + hue_quotient;
        endcase
        out_data[1] <= (Val_cal[PIPILINE-4] == 0)?(0):(sat_quotient >= (1<<HSV_DEPTH))?(~0):(sat_quotient);
        if(RGB_DEPTH >= HSV_DEPTH) out_data[0] <= Val_cal[PIPILINE-4] >> (RGB_DEPTH-HSV_DEPTH);
        else out_data[0] <= Val_cal[PIPILINE-4] << (HSV_DEPTH-RGB_DEPTH);
    end
  end
end

//注意 该除法器模块按照DATA_WIDTH=8,HSV_DEPTH=8,latency=5配置
Hue_Cal_Division Hue_Cal_Division_inst(
	.clk(clk), //input clk
	.rstn(~reset), //input rstn
	.dividend(hue_dividend), //input [16:0] dividend
	.divisor(hue_divisor), //input [10:0] divisor
	.quotient(hue_quotient) //output [16:0] quotient
);

//注意 该除法器模块按照DATA_WIDTH=8,HSV_DEPTH=8,latency=5配置
Sat_Cal_Division your_instance_name(
	.clk(clk), //input clk
	.rstn(~reset), //input rstn
	.dividend(sat_dividend), //input [15:0] dividend
	.divisor(sat_divisor), //input [7:0] divisor
	.quotient(sat_quotient) //output [15:0] quotient
);

endmodule