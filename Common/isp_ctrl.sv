`include "ISP_REGISTER.v"

module isp_ctrl(
  input wire        clk    ,
  input wire        reset  ,
  input wire        wr_en  ,
  input wire [15:0] wr_data,
  input wire [15:0] wr_addr,
  output reg  [15:0] isp_vector[16]
);

integer i;
always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<16;i=i+1) isp_vector[i] <= 0;
        isp_vector[`ADDR_ISP_IN_PIXEL_X  ] <= `DEFAULT_ISP_IN_PIXEL_X  ;
        isp_vector[`ADDR_ISP_IN_PIXEL_Y  ] <= `DEFAULT_ISP_IN_PIXEL_Y  ;
        isp_vector[`ADDR_ISP_OUT_OFFSET_X] <= `DEFAULT_ISP_OUT_OFFSET_X;
        isp_vector[`ADDR_ISP_OUT_OFFSET_Y] <= `DEFAULT_ISP_OUT_OFFSET_Y;
        isp_vector[`ADDR_ISP_OUT_PIXEL_X ] <= `DEFAULT_ISP_OUT_PIXEL_X ;
        isp_vector[`ADDR_ISP_OUT_PIXEL_Y ] <= `DEFAULT_ISP_OUT_PIXEL_Y ;
        isp_vector[`ADDR_ISP_GAIN_RED    ] <= `DEFAULT_ISP_GAIN_RED    ;
        isp_vector[`ADDR_ISP_GAIN_GREEN  ] <= `DEFAULT_ISP_GAIN_GREEN  ;
        isp_vector[`ADDR_ISP_GAIN_BLUE   ] <= `DEFAULT_ISP_GAIN_BLUE   ;
        isp_vector[`ADDR_ISP_CTRL        ] <= `DEFAULT_ISP_CTRL        ;
        isp_vector[`ADDR_DPC_THRESHOLD   ] <= `DEFAULT_DPC_THRESHOLD   ;
        isp_vector[`ADDR_HUE_OFFSET      ] <= `DEFAULT_HUE_OFFSET      ;
        isp_vector[`ADDR_SAT_GAIN_LOSS   ] <= `DEFAULT_SAT_GAIN_LOSS   ;
        isp_vector[`ADDR_VAL_GAIN_LOSS   ] <= `DEFAULT_VAL_GAIN_LOSS   ;
        isp_vector[`ADDR_NATURE_SAT_GAIN ] <= `DEFAULT_NATURE_SAT_GAIN ;
    end else if(wr_en) isp_vector[wr_addr] <= wr_data;
end




endmodule