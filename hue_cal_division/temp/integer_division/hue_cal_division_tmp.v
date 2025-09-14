//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.02
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138
//Device Version: B
//Created Time: Thu Nov  7 09:48:51 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Hue_Cal_Division your_instance_name(
		.clk(clk), //input clk
		.rstn(rstn), //input rstn
		.dividend(dividend), //input [16:0] dividend
		.divisor(divisor), //input [10:0] divisor
		.quotient(quotient) //output [16:0] quotient
	);

//--------Copy end-------------------
