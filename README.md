# 2024年FPGA创新创业竞赛 Gowin ISP设计源代码

OurEDA

上位机即软件部分在这里：[here](https://github.com/Alivenderwww/OurEDA-Gowin-ISP-Software-Deigin)

！！！部分使用了Gowin的Bram、Dram、Div等IP核，移植注意。

可实现流水线ISP图像处理，从**RAW格式数据流**经过**去马赛克、DPC去坏点、RGB通道增益调整、HSV通道增益调整、自动白平衡、Gamma矫正、饱和度、自然饱和度调增、裁切**、最终处理为RGB格式数据流。

每一个模块都可以通过向量控制模块启动关闭、参数调整。