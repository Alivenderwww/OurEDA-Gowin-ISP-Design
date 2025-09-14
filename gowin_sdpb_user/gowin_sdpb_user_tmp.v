//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.02
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138
//Device Version: B
//Created Time: Thu Nov 14 12:58:19 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_SDPB_USER your_instance_name(
        .dout(dout), //output [7:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .oce(oce), //input oce
        .reset(reset), //input reset
        .ada(ada), //input [11:0] ada
        .din(din), //input [7:0] din
        .adb(adb) //input [11:0] adb
    );

//--------Copy end-------------------
