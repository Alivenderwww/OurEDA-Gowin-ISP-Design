//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.02
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138
//Device Version: B
//Created Time: Thu Nov  7 18:33:07 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Square_linear_div your_instance_name(
		.clk(clk), //input clk
		.rstn(rstn), //input rstn
		.dividend(dividend), //input [15:0] dividend
		.divisor(divisor), //input [7:0] divisor
		.quotient(quotient) //output [15:0] quotient
	);

//--------Copy end-------------------
