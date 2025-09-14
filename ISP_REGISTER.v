`define ADDR_ISP_IN_PIXEL_X     16'h0000   //ISP模块输入图像-长
`define ADDR_ISP_IN_PIXEL_Y     16'h0001   //ISP模块输入图像-宽
`define ADDR_ISP_OUT_OFFSET_X   16'h0002   //ISP模块输出图像相较输入图像左上角偏移量-X
`define ADDR_ISP_OUT_OFFSET_Y   16'h0003   //ISP模块输出图像相较输入图像左上角偏移量-Y
`define ADDR_ISP_OUT_PIXEL_X    16'h0004   //ISP模块输出图像-长
`define ADDR_ISP_OUT_PIXEL_Y    16'h0005   //ISP模块输出图像-宽
`define ADDR_ISP_GAIN_RED       16'h0006   //ISP模块色彩矫正模块-红色校正系数
`define ADDR_ISP_GAIN_GREEN     16'h0007   //ISP模块色彩矫正模块-绿色校正系数
`define ADDR_ISP_GAIN_BLUE      16'h0008   //ISP模块色彩矫正模块-蓝色校正系数
`define ADDR_ISP_CTRL           16'h0009   //ISP模块各模块控制位
/*                                              bit0: 总开关 
                                                bit1: 启用DPC矫正
                                                bit2: 启用DPC-label标注
                                                bit3: 启用Demosaic
                                                bit4: 启用色彩校正ColorBlender
                                                bit[6:5]: 输入图像RAWTYPE, 0:grbg, 1:rggb, 2:bggr, 3:gbrg
                                                bit7: 启用Crop裁切
                                                bit8: 启用Crop模块自动处理一帧内行数不足，行数不足也可以输出正确时序，但帧率会下降，且下一帧画面会接在上一帧下面
                                                bit9: 启用AWB
                                                bit10: 启用HSV色彩空间转换, 此项开启后饱和度调整有效
                                                bit11: 启用Huw
                                                bit12: 启用Sat
                                                bit13: 启用Val
                                                bit14: 启用自然饱和度
                                                bit15: 启用Gamma矫正
*/
`define ADDR_DPC_THRESHOLD        16'h000A   //DPC模块-阈值
`define ADDR_HUE_OFFSET           16'h000B   //色度偏移量 bit[7:0]=offset
`define ADDR_SAT_GAIN_LOSS        16'h000C   //饱和度增益减益 bit[15:8]=gain, bit[7:0]=loss
`define ADDR_VAL_GAIN_LOSS        16'h000D   //明度增益减益 bit[15:8]=gain, bit[7:0]=loss
`define ADDR_NATURE_SAT_GAIN      16'h000E   //自然饱和度增减益 bit[15:8]=gain, bit[7:0]=loss
//饱和度调整公式: new_sat = sat * ((GAIN-LOSS)/16'hFFFF + 1);
//GAIN-LOSS=0 无变化 GAIN-LOSS>0 饱和度增加 GAIN-LOSS<0 饱和度降低

`define DEFAULT_ISP_IN_PIXEL_X     16'd1280
`define DEFAULT_ISP_IN_PIXEL_Y     16'd1024
`define DEFAULT_ISP_OUT_OFFSET_X   16'd16
`define DEFAULT_ISP_OUT_OFFSET_Y   16'd8 
`define DEFAULT_ISP_OUT_PIXEL_X    16'd640
`define DEFAULT_ISP_OUT_PIXEL_Y    16'd480
`define DEFAULT_ISP_GAIN_RED       16'd50
`define DEFAULT_ISP_GAIN_GREEN     16'd50
`define DEFAULT_ISP_GAIN_BLUE      16'd50
`define DEFAULT_ISP_CTRL           16'b0000_0011_1100_1011
`define DEFAULT_DPC_THRESHOLD      16'd80
`define DEFAULT_HUE_OFFSET         {8'd0,8'd0}
`define DEFAULT_SAT_GAIN_LOSS      {8'd0,8'd0}
`define DEFAULT_VAL_GAIN_LOSS      {8'd0,8'd0}
`define DEFAULT_NATURE_SAT_GAIN    {8'd0,1'b0,7'd0}