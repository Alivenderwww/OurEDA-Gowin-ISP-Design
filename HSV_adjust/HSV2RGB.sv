module HSV2RGB #(          //HSV: hue, saturation, value. (same as HSB(Brightness))
    parameter HSV_DEPTH = 8,
    parameter RGB_DEPTH = 8 //仅在HSV_DEPTH=8, RGB_DEPTH=8测试没问题
) (
    input wire                     clk,  
    input wire                     reset, 

    input wire                     in_valid,
    input wire  [HSV_DEPTH - 1:0]  in_data[3],
    input wire  [7:0]              in_user,

    output wire                    out_valid,
    output reg  [RGB_DEPTH - 1:0]  out_data[3],
    output wire    [7:0]           out_user,

    input wire                     in_ready,
    output wire                    out_ready
);

reg [HSV_DEPTH-1:0] hue, hue0, hue1, hue2, hue3;
reg [HSV_DEPTH-1:0] val, val0, val1, val2, val3;
reg [HSV_DEPTH-1:0] sat, sat0;
reg [HSV_DEPTH-1:0] hue_match_MAX;

reg [4*HSV_DEPTH - 1 :0] p, q, t;
reg [  HSV_DEPTH - 1 :0] f, _f, _sat;
reg [  HSV_DEPTH - 1 :0] p__, q__, t__;
reg [2*HSV_DEPTH - 1 :0] fsat, _fsat, __fsat;
 
localparam MAX  = (1<<HSV_DEPTH),
           MAX0 = ((MAX - 0   )/6) + 0    + 1,//42  + 1 when dep=8
           MAX1 = ((MAX - MAX0)/5) + MAX0 + 1,//84  + 1 when dep=8
           MAX2 = ((MAX - MAX1)/4) + MAX1 + 1,//127 + 1 when dep=8
           MAX3 = ((MAX - MAX2)/3) + MAX2 + 1,//170 + 1 when dep=8
           MAX4 = ((MAX - MAX3)/2) + MAX3 + 1,//213 + 1 when dep=8
           MAX5 = ((MAX - MAX4)/1) + MAX4 + 1;//256 + 1 when dep=8

localparam PIPILINE = 6;

reg [7:0] pipeline_user[PIPILINE];
reg [PIPILINE-1:0] pipeline_valid;
wire pipeline_running;
assign pipeline_running = in_ready | ~pipeline_valid[PIPILINE-1];

//out_ready ：只要本模块可以接收数据就一直拉高
assign out_ready = pipeline_running;
//out_valid ：只要本模块可以发出数据就一直拉高
assign out_valid = pipeline_valid[PIPILINE-1];
assign out_user = pipeline_user[PIPILINE-1];

integer i;
always @(posedge clk) begin
  if(reset) begin
    for(i=0;i<PIPILINE;i=i+1) pipeline_user[i] <= 0;
    pipeline_valid <= 0;
  end else if(pipeline_running) begin
    
    pipeline_valid <= {pipeline_valid[PIPILINE-2:0], in_valid};
    for(i=1;i<PIPILINE;i=i+1) pipeline_user[i] <= (pipeline_valid[i-1])?(pipeline_user[i-1]):(pipeline_user[i]);

    if(in_valid) begin
        hue <= in_data[2];
        sat <= in_data[1];
        val <= in_data[0];
        pipeline_user[0] <= in_user;
    end

    if(pipeline_valid[0]) begin
        {hue0,sat0,val0} <= {hue,sat,val};
        f <= (hue - hue_match_MAX) * 6;
    end

    if(pipeline_valid[1]) begin
        {hue1,val1} <= {hue0,val0};
        _sat   <= ~sat0;
        _fsat  <= ~( f * sat0);
        __fsat <= ~(_f * sat0);
    end

    if(pipeline_valid[2]) begin
        {hue2,val2} <= {hue1,val1};
        p <= (val1 * _sat  );
        q <= (val1 * _fsat );
        t <= (val1 * __fsat);
    end

    if(pipeline_valid[3]) begin
        {hue3,val3} <= {hue2,val2};
        p__ <= p[  HSV_DEPTH +: HSV_DEPTH];
        q__ <= q[2*HSV_DEPTH +: HSV_DEPTH];
        t__ <= t[2*HSV_DEPTH +: HSV_DEPTH];
    end
    if(pipeline_valid[4]) begin
        if      (hue3 < MAX0) {out_data[2],out_data[1],out_data[0]} = {val3[HSV_DEPTH-1 -: RGB_DEPTH], t__[HSV_DEPTH-1 -: RGB_DEPTH], p__[HSV_DEPTH-1 -: RGB_DEPTH]};
        else if (hue3 < MAX1) {out_data[2],out_data[1],out_data[0]} = { q__[HSV_DEPTH-1 -: RGB_DEPTH],val3[HSV_DEPTH-1 -: RGB_DEPTH], p__[HSV_DEPTH-1 -: RGB_DEPTH]};
        else if (hue3 < MAX2) {out_data[2],out_data[1],out_data[0]} = { p__[HSV_DEPTH-1 -: RGB_DEPTH],val3[HSV_DEPTH-1 -: RGB_DEPTH], t__[HSV_DEPTH-1 -: RGB_DEPTH]};
        else if (hue3 < MAX3) {out_data[2],out_data[1],out_data[0]} = { p__[HSV_DEPTH-1 -: RGB_DEPTH], q__[HSV_DEPTH-1 -: RGB_DEPTH],val3[HSV_DEPTH-1 -: RGB_DEPTH]};
        else if (hue3 < MAX4) {out_data[2],out_data[1],out_data[0]} = { t__[HSV_DEPTH-1 -: RGB_DEPTH], p__[HSV_DEPTH-1 -: RGB_DEPTH],val3[HSV_DEPTH-1 -: RGB_DEPTH]};
        else                  {out_data[2],out_data[1],out_data[0]} = {val3[HSV_DEPTH-1 -: RGB_DEPTH], p__[HSV_DEPTH-1 -: RGB_DEPTH], q__[HSV_DEPTH-1 -: RGB_DEPTH]};
    end
  end
end

always @(*) begin
    if     (hue < MAX0) hue_match_MAX = 0;
    else if(hue < MAX1) hue_match_MAX = MAX0;
    else if(hue < MAX2) hue_match_MAX = MAX1;
    else if(hue < MAX3) hue_match_MAX = MAX2;
    else if(hue < MAX4) hue_match_MAX = MAX3;
    else                hue_match_MAX = MAX4;

    _f = ~f;
end

endmodule