//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.02
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138
//Device Version: B
//Created Time: Tue Nov  5 11:55:52 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	AWB_Integer_Division your_instance_name(
		.clk(clk), //input clk
		.rstn(rstn), //input rstn
		.dividend(dividend), //input [41:0] dividend
		.divisor(divisor), //input [33:0] divisor
		.quotient(quotient) //output [41:0] quotient
	);

//--------Copy end-------------------
