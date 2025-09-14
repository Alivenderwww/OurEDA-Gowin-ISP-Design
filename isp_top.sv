`timescale 1ns / 1ps
`include "ISP_REGISTER.v"
/* TODO 1. ISP寄存器配置模式，如配置是否启用什么什么矫正，矫正系数多少。能读能写。选好通信协议，要不要用AXI？
        2. 白平衡，GAMMA矫正。白平衡做RAW白平衡吗？
        3. 寄存器中应该有一个寄存器标识ISP运行状态。比如裁切模块，直接修改寄存器值数据就乱了。
        4. 缩放模块。如何处理模块进出数据量不匹配？
        5. 旋转模块。这怎么做？
        6. ISP不应该只有一条线，比如存进SDRAM后，读出来时也可以做处理。
*/
module isp_top #(
    parameter reg [15:0] DATA_WIDTH  = 12,
    parameter reg [ 4:0] COLOR_DEPTH = 8
) (
    // 基本信号
    input wire camera_clk,
    input wire isp_clk,
    input wire ctrl_clk,
    input wire reset,

    // 控制信号
    input wire [15:0] ctrl_addr,
    input wire [15:0] ctrl_data,
    input wire        ctrl_en,

    // 输入线
    input  wire                  in_valid,
    output wire                  out_ready,
    input  wire [DATA_WIDTH-1:0] in_data,   // 数据输入线
    input  wire                  in_fsync,  // 帧同步，在两帧间隔间拉高，标志着一帧的结束和新帧的开始
    input  wire                  in_hsync,  // 行同步，在一行内持续拉高，一行结束后拉低。

    // 输出线
    output wire                     out_valid,
    input  wire                     in_ready,
    output wire [3*COLOR_DEPTH-1:0] out_data,  // 数据输出线
    output wire [7:0]               out_user   //自定义数据线. [0]是hstart标志位, [1]是fstart标志位
);

wire [DATA_WIDTH-1:0]  DPC_data;
wire [DATA_WIDTH-1:0]  AWB_Gray_World_data;
wire [DATA_WIDTH-1:0]  adapter_data;
wire [DATA_WIDTH-1:0]  Demosaic_data[3];
wire [DATA_WIDTH-1:0]  Windows_DPC_data[5*5];
wire [DATA_WIDTH-1:0]  Windows_Demosaic_data[3*3];
wire [COLOR_DEPTH-1:0] Blender_data[3];
wire [COLOR_DEPTH-1:0] RGB2HSV_data[3];
wire [COLOR_DEPTH-1:0] HSV_Adjust_data[3];
wire [COLOR_DEPTH-1:0] HSV2RGB_data[3];
wire [COLOR_DEPTH-1:0] Nature_Sat_Adjust_data[3];
wire [COLOR_DEPTH-1:0] Gamma_data[3];
wire [COLOR_DEPTH-1:0] Crop_data[3];
wire [7:0] adapter_user,  Windows_DPC_user , DPC_user , AWB_Gray_World_user , Windows_Demosaic_user , Demosaic_user , Blender_user , RGB2HSV_user , HSV_Adjust_user , HSV2RGB_user , Nature_Sat_Adjust_user , Gamma_user , Crop_user ;
wire       adapter_valid, Windows_DPC_valid, DPC_valid, AWB_Gray_World_valid, Windows_Demosaic_valid, Demosaic_valid, Blender_valid, RGB2HSV_valid, HSV_Adjust_valid, HSV2RGB_valid, Nature_Sat_Adjust_valid, Gamma_valid, Crop_valid;
wire                      Windows_DPC_ready, DPC_ready, AWB_Gray_World_ready, Windows_Demosaic_ready, Demosaic_ready, Blender_ready, RGB2HSV_ready, HSV_Adjust_ready, HSV2RGB_ready, Nature_Sat_Adjust_ready, Gamma_ready, Crop_ready;
assign out_valid = Crop_valid;
assign out_ready = Windows_DPC_ready;
// assign out_data = {Crop_data[2], Crop_data[1], Crop_data[0]};
assign out_data = {Crop_data[0], Crop_data[1], Crop_data[2]}; //RGB -> BGR
assign out_user = Crop_user;

fifo_isp_adapter #(
  .DATA_WIDTH (DATA_WIDTH)
)fifo_isp_adapter_u(
    .reset      (reset          ),

	.camera_clk (camera_clk     ),
	.in_valid   (in_valid       ),
	.in_data    (in_data        ),
	.in_fsync   (in_fsync       ),
	.in_hsync   (in_hsync       ),

	.isp_clk    (isp_clk        ),
	.out_valid  (adapter_valid  ),
	.out_data   (adapter_data   ),
    .out_user   (adapter_user   )
);

wire [15:0] isp_vector[16];
isp_ctrl isp_ctrl(
    .clk        (ctrl_clk   ),
    .reset      (reset      ),

    .wr_en      (ctrl_en    ),
    .wr_data    (ctrl_data  ),
    .wr_addr    (ctrl_addr  ),

    .isp_vector (isp_vector )
);

Windows #(
    .DATA_WIDTH      (DATA_WIDTH),
    .WINDOWS_WIDTH   (5),
    .WINDOWS_ANCHOR_X(2),
    .WINDOWS_ANCHOR_Y(2)
)Windows_DPC_inst(
    .clk        (isp_clk            ),
    .reset      (reset              ),

    .in_valid   (adapter_valid      ),
    .in_data    (adapter_data       ),
    .in_user    (adapter_user       ),
    
    .out_valid  (Windows_DPC_valid  ),
    .out_data   (Windows_DPC_data   ),
    .out_user   (Windows_DPC_user   ),

    .in_ready   (DPC_ready          ),
    .out_ready  (Windows_DPC_ready  )
);

DPC #(
    .DATA_WIDTH   (DATA_WIDTH)
)DPC_inst(
    .clk        (isp_clk                        ),
    .reset      (reset                          ),

    .in_valid   (Windows_DPC_valid              ),
    .in_data    (Windows_DPC_data               ),
    .in_user    (Windows_DPC_user               ),

    .out_valid  (DPC_valid                      ),
    .out_data   (DPC_data                       ),
    .out_user   (DPC_user                       ),

    .in_ready   (AWB_Gray_World_ready           ),
    .out_ready  (DPC_ready                      ),

    .isp_ctrl   (isp_vector[`ADDR_ISP_CTRL]     ),
    .threshold  (isp_vector[`ADDR_DPC_THRESHOLD])
);

AWB_Gray_World #(
    .DATA_WIDTH(DATA_WIDTH)
)AWB_Gray_World_inst(
    .clk        (isp_clk                    ),
    .reset      (reset                      ),

    .in_valid   (DPC_valid                  ),
    .in_data    (DPC_data                   ),
    .in_user    (DPC_user                   ),

    .out_valid  (AWB_Gray_World_valid       ),
    .out_data   (AWB_Gray_World_data        ),
    .out_user   (AWB_Gray_World_user        ),

    .in_ready   (Windows_Demosaic_ready     ),
    .out_ready  (AWB_Gray_World_ready       ),

    .isp_ctrl   (isp_vector[`ADDR_ISP_CTRL] )
);

Windows #(
    .DATA_WIDTH      (DATA_WIDTH),
    .WINDOWS_WIDTH   (3),
    .WINDOWS_ANCHOR_X(1),
    .WINDOWS_ANCHOR_Y(1)
)Windows_Demosaic_inst(
    .clk        (isp_clk                ),
    .reset      (reset                  ),

    .in_valid   (AWB_Gray_World_valid   ),
    .in_data    (AWB_Gray_World_data    ),
    .in_user    (AWB_Gray_World_user    ),

    .out_valid  (Windows_Demosaic_valid ),
    .out_data   (Windows_Demosaic_data  ),
    .out_user   (Windows_Demosaic_user  ),

    .in_ready   (Demosaic_ready         ),
    .out_ready  (Windows_Demosaic_ready )
);

Demosaic #(
    .DATA_WIDTH   (DATA_WIDTH),
    .WINDOW_LENGTH(3         )
)Demosaic_inst(
    .clk        (isp_clk                    ),
    .reset      (reset                      ),

    .in_valid   (Windows_Demosaic_valid     ),
    .in_data    (Windows_Demosaic_data      ),
    .in_user    (Windows_Demosaic_user      ),

    .out_valid  (Demosaic_valid             ),
    .out_data   (Demosaic_data              ),
    .out_user   (Demosaic_user              ),

    .in_ready   (Blender_ready              ),
    .out_ready  (Demosaic_ready             ),

    .isp_ctrl   (isp_vector[`ADDR_ISP_CTRL] )
);

ColorBlender #(
    .DATA_WIDTH(DATA_WIDTH ),  // 输入图像的色深
    .OUT_DEPTH (COLOR_DEPTH)   // 输出图像的色深
) ColorBlender_inst(
    .clk        (isp_clk                            ),
    .reset      (reset                              ),

    .in_valid   (Demosaic_valid                     ),
    .in_data    (Demosaic_data                      ),
    .in_user    (Demosaic_user                      ),

    .out_valid  (Blender_valid                      ),
    .out_data   (Blender_data                       ),
    .out_user   (Blender_user                       ),

    .in_ready   (RGB2HSV_ready                      ),
    .out_ready  (Blender_ready                      ),

    .isp_ctrl   (isp_vector[`ADDR_ISP_CTRL]         ),
    .gain_red   (isp_vector[`ADDR_ISP_GAIN_RED]     ),
    .gain_green (isp_vector[`ADDR_ISP_GAIN_GREEN]   ),
    .gain_blue  (isp_vector[`ADDR_ISP_GAIN_BLUE]    )
);

RGB2HSV #(
    .RGB_DEPTH (COLOR_DEPTH ),
    .HSV_DEPTH (COLOR_DEPTH )
) RGB2HSV_inst(
    .clk        (isp_clk            ),
    .reset      (reset              ),

    .in_valid   (Blender_valid      ),
    .in_data    (Blender_data       ),
    .in_user    (Blender_user       ),

    .out_valid  (RGB2HSV_valid      ),
    .out_data   (RGB2HSV_data       ),
    .out_user   (RGB2HSV_user       ),

    .in_ready   (HSV_Adjust_ready   ),
    .out_ready  (RGB2HSV_ready      )
);

HSV_Adjust 
#(
    .HSV_DEPTH (COLOR_DEPTH )
) u_HSV_Adjust(
    .clk                (isp_clk                        ),
    .reset              (reset                          ),

    .in_valid           (RGB2HSV_valid                  ),
    .in_data            (RGB2HSV_data                   ),
    .in_user            (RGB2HSV_user                   ),

    .out_valid          (HSV_Adjust_valid               ),
    .out_data           (HSV_Adjust_data                ),
    .out_user           (HSV_Adjust_user                ),

    .in_ready           (HSV2RGB_ready                  ),
    .out_ready          (HSV_Adjust_ready               ),

    .isp_ctrl           (isp_vector[`ADDR_ISP_CTRL]     ),
    .isp_hue_offset     (isp_vector[`ADDR_HUE_OFFSET]   ),
    .isp_sat_gain_loss  (isp_vector[`ADDR_SAT_GAIN_LOSS]),
    .isp_val_gain_loss  (isp_vector[`ADDR_VAL_GAIN_LOSS])
);

HSV2RGB 
#(
    .HSV_DEPTH (COLOR_DEPTH ),
    .RGB_DEPTH (COLOR_DEPTH )
) u_HSV2RGB(
    .clk        (isp_clk                ),
    .reset      (reset                  ),

    .in_valid   (HSV_Adjust_valid       ),
    .in_data    (HSV_Adjust_data        ),
    .in_user    (HSV_Adjust_user        ),

    .out_valid  (HSV2RGB_valid          ),
    .out_data   (HSV2RGB_data           ),
    .out_user   (HSV2RGB_user           ),

    .in_ready   (Nature_Sat_Adjust_ready),
    .out_ready  (HSV2RGB_ready          )
);

Nature_Sat_Adjust #(
    .COLOR_DEPTH (COLOR_DEPTH )
) u_Nature_Sat_Adjust(
    .clk            (isp_clk                            ),
    .reset          (reset                              ),

    .in_valid       (HSV2RGB_valid                      ),
    .in_data        (HSV2RGB_data                       ),
    .in_user        (HSV2RGB_user                       ),

    .out_valid      (Nature_Sat_Adjust_valid            ),
    .out_data       (Nature_Sat_Adjust_data             ),
    .out_user       (Nature_Sat_Adjust_user             ),

    .in_ready       (Gamma_ready                        ),
    .out_ready      (Nature_Sat_Adjust_ready            ),

    .isp_ctrl       (isp_vector[`ADDR_ISP_CTRL]             ),
    .isp_Adjustment (isp_vector[`ADDR_NATURE_SAT_GAIN][7:0] )
);

GammaCorrection_Pipeline #(
    .COLOR_DEPTH (COLOR_DEPTH )
) u_GammaCorrection_Pipeline(
    .clk        (isp_clk                ),
    .rst        (reset                  ),

    .i_valid    (Nature_Sat_Adjust_valid),
    .i_data     (Nature_Sat_Adjust_data ),
    .i_user     (Nature_Sat_Adjust_user ),

    .o_valid    (Gamma_valid            ),
    .o_data     (Gamma_data             ),
    .o_user     (Gamma_user             ),

    .i_ready    (Crop_ready             ),
    .o_ready    (Gamma_ready            ),

    .isp_ctrl   (isp_vector[`ADDR_ISP_CTRL])
);



Crop #(
  .COLOR_DEPTH(COLOR_DEPTH)
) Crop_inst(
    .clk                (isp_clk                            ),
    .reset              (reset                              ),

    .in_valid           (Gamma_valid                        ),
    .in_data            (Gamma_data                         ),
    .in_user            (Gamma_user                         ),

    .out_valid          (Crop_valid                         ),
    .out_data           (Crop_data                          ),
    .out_user           (Crop_user                          ),

    .in_ready           (in_ready                           ),
    .out_ready          (Crop_ready                         ),

    .isp_ctrl           (isp_vector[`ADDR_ISP_CTRL]         ),
    .isp_in_pixel_x     (isp_vector[`ADDR_ISP_IN_PIXEL_X]   ),
    .isp_in_pixel_y     (isp_vector[`ADDR_ISP_IN_PIXEL_Y]   ),
    .isp_out_offset_x   (isp_vector[`ADDR_ISP_OUT_OFFSET_X] ),
    .isp_out_offset_y   (isp_vector[`ADDR_ISP_OUT_OFFSET_Y] ),
    .isp_out_pixel_x    (isp_vector[`ADDR_ISP_OUT_PIXEL_X]  ),
    .isp_out_pixel_y    (isp_vector[`ADDR_ISP_OUT_PIXEL_Y]  )
);

endmodule
