`include "C:/_Project/FPGA/Gowin/Gowin_verilog/isp/Gamma/Common/color.svh"
`include "C:/_Project/FPGA/Gowin/Gowin_verilog/isp/Gamma/Common/common.svh"
//`include "C:/_Project/FPGA/Gowin/Gowin_verilog/isp/Gamma/Common/vector.svh"

module GammaCorrection_Pipeline
  import common::*;
#(
    parameter uint COLOR_DEPTH = 8
) (
    input var clk,
    input var rst,

    input var i_ready,
    input var i_valid,
    input var [COLOR_DEPTH - 1 : 0] i_data[3],

    output var o_ready,
    output var o_valid,
    output var [COLOR_DEPTH - 1 : 0] o_data[3],

    input var  [7:0] i_user,
    output var [7:0] o_user,

    // input bit [COLOR_DEPTH - 1:0] i_Gtable[256],
    input var [15:0] isp_ctrl
);
  bit [COLOR_DEPTH - 1:0] i_Gtable[256];
  wire gamma_en;
  assign gamma_en = isp_ctrl[0] & isp_ctrl[15];
  // pipeline level
  localparam uint PIPELINELEVEL = 1 + 1;

  // Define Color
  typedef Color#(COLOR_DEPTH) _Color;
  Color #(COLOR_DEPTH)::color_t color = '{0, 0, 0};

  // shift queue: horizon sync and flame sync
  typedef Array#(
      .T(bit [7:0]),
      .LENGTH(PIPELINELEVEL - 1)
  ) User;
  bit [7:0] user[PIPELINELEVEL - 1];

  // Pipeline status
  typedef Array#(
      .T(bit),
      .LENGTH(PIPELINELEVEL - 1)
  ) Pipe;
  bit pipe_state[PIPELINELEVEL - 1];

  assign o_ready = i_ready;

  // Pipeline in: Read data
  always_ff @(posedge clk) begin : Pipeline_in
    if (rst) begin
      pipe_state <= Pipe::f_fill(0);
      user <= User::f_fill(0);
    end else begin

      // read sync edge signal and push front
      user <= User::f_pushFront(user, i_user);

      // push front i_valid signal
      pipe_state <= Pipe::f_pushFront(pipe_state, i_valid);

      // read color data
      if (i_valid) begin
        color <= _Color::f_fromRGB(i_data[2], i_data[1], i_data[0]);
      end else begin
      end
    end
  end

  // Pipeline 0: Send data
  always_ff @(posedge clk) begin : Pipeline_0
    if (rst) begin
      o_data  <= '{default: 0};
      o_user  <= 0;
      o_valid <= 0;
    end else if (pipe_state[0]) begin

      // send the last sync signal from queue
      o_user <= User::f_getBack(user);

      // read adjust data from gamma table
      if(gamma_en) begin
        {o_data[2], o_data[1], o_data[0]} <= {
          i_Gtable[color.red], i_Gtable[color.green], i_Gtable[color.blue]
        };
      end else begin
        {o_data[2], o_data[1], o_data[0]} <= {color.red, color.green, color.blue};
      end
      o_valid <= 1;

    end else begin
      o_valid <= 0;
    end
  end


assign i_Gtable[0] = 8'h0;
assign i_Gtable[1] = 8'h9;
assign i_Gtable[2] = 8'he;
assign i_Gtable[3] = 8'h12;
assign i_Gtable[4] = 8'h16;
assign i_Gtable[5] = 8'h19;
assign i_Gtable[6] = 8'h1c;
assign i_Gtable[7] = 8'h1e;
assign i_Gtable[8] = 8'h21;
assign i_Gtable[9] = 8'h23;
assign i_Gtable[10] = 8'h25;
assign i_Gtable[11] = 8'h28;
assign i_Gtable[12] = 8'h2a;
assign i_Gtable[13] = 8'h2c;
assign i_Gtable[14] = 8'h2e;
assign i_Gtable[15] = 8'h30;
assign i_Gtable[16] = 8'h32;
assign i_Gtable[17] = 8'h33;
assign i_Gtable[18] = 8'h35;
assign i_Gtable[19] = 8'h37;
assign i_Gtable[20] = 8'h39;
assign i_Gtable[21] = 8'h3a;
assign i_Gtable[22] = 8'h3c;
assign i_Gtable[23] = 8'h3d;
assign i_Gtable[24] = 8'h3f;
assign i_Gtable[25] = 8'h41;
assign i_Gtable[26] = 8'h42;
assign i_Gtable[27] = 8'h44;
assign i_Gtable[28] = 8'h45;
assign i_Gtable[29] = 8'h46;
assign i_Gtable[30] = 8'h48;
assign i_Gtable[31] = 8'h49;
assign i_Gtable[32] = 8'h4b;
assign i_Gtable[33] = 8'h4c;
assign i_Gtable[34] = 8'h4d;
assign i_Gtable[35] = 8'h4f;
assign i_Gtable[36] = 8'h50;
assign i_Gtable[37] = 8'h51;
assign i_Gtable[38] = 8'h53;
assign i_Gtable[39] = 8'h54;
assign i_Gtable[40] = 8'h55;
assign i_Gtable[41] = 8'h57;
assign i_Gtable[42] = 8'h58;
assign i_Gtable[43] = 8'h59;
assign i_Gtable[44] = 8'h5a;
assign i_Gtable[45] = 8'h5b;
assign i_Gtable[46] = 8'h5d;
assign i_Gtable[47] = 8'h5e;
assign i_Gtable[48] = 8'h5f;
assign i_Gtable[49] = 8'h60;
assign i_Gtable[50] = 8'h61;
assign i_Gtable[51] = 8'h62;
assign i_Gtable[52] = 8'h64;
assign i_Gtable[53] = 8'h65;
assign i_Gtable[54] = 8'h66;
assign i_Gtable[55] = 8'h67;
assign i_Gtable[56] = 8'h68;
assign i_Gtable[57] = 8'h69;
assign i_Gtable[58] = 8'h6a;
assign i_Gtable[59] = 8'h6b;
assign i_Gtable[60] = 8'h6c;
assign i_Gtable[61] = 8'h6d;
assign i_Gtable[62] = 8'h6e;
assign i_Gtable[63] = 8'h70;
assign i_Gtable[64] = 8'h71;
assign i_Gtable[65] = 8'h72;
assign i_Gtable[66] = 8'h73;
assign i_Gtable[67] = 8'h74;
assign i_Gtable[68] = 8'h75;
assign i_Gtable[69] = 8'h76;
assign i_Gtable[70] = 8'h77;
assign i_Gtable[71] = 8'h78;
assign i_Gtable[72] = 8'h79;
assign i_Gtable[73] = 8'h7a;
assign i_Gtable[74] = 8'h7b;
assign i_Gtable[75] = 8'h7c;
assign i_Gtable[76] = 8'h7d;
assign i_Gtable[77] = 8'h7e;
assign i_Gtable[78] = 8'h7f;
assign i_Gtable[79] = 8'h7f;
assign i_Gtable[80] = 8'h80;
assign i_Gtable[81] = 8'h81;
assign i_Gtable[82] = 8'h82;
assign i_Gtable[83] = 8'h83;
assign i_Gtable[84] = 8'h84;
assign i_Gtable[85] = 8'h85;
assign i_Gtable[86] = 8'h86;
assign i_Gtable[87] = 8'h87;
assign i_Gtable[88] = 8'h88;
assign i_Gtable[89] = 8'h89;
assign i_Gtable[90] = 8'h8a;
assign i_Gtable[91] = 8'h8b;
assign i_Gtable[92] = 8'h8b;
assign i_Gtable[93] = 8'h8c;
assign i_Gtable[94] = 8'h8d;
assign i_Gtable[95] = 8'h8e;
assign i_Gtable[96] = 8'h8f;
assign i_Gtable[97] = 8'h90;
assign i_Gtable[98] = 8'h91;
assign i_Gtable[99] = 8'h92;
assign i_Gtable[100] = 8'h93;
assign i_Gtable[101] = 8'h93;
assign i_Gtable[102] = 8'h94;
assign i_Gtable[103] = 8'h95;
assign i_Gtable[104] = 8'h96;
assign i_Gtable[105] = 8'h97;
assign i_Gtable[106] = 8'h98;
assign i_Gtable[107] = 8'h98;
assign i_Gtable[108] = 8'h99;
assign i_Gtable[109] = 8'h9a;
assign i_Gtable[110] = 8'h9b;
assign i_Gtable[111] = 8'h9c;
assign i_Gtable[112] = 8'h9d;
assign i_Gtable[113] = 8'h9d;
assign i_Gtable[114] = 8'h9e;
assign i_Gtable[115] = 8'h9f;
assign i_Gtable[116] = 8'ha0;
assign i_Gtable[117] = 8'ha1;
assign i_Gtable[118] = 8'ha2;
assign i_Gtable[119] = 8'ha2;
assign i_Gtable[120] = 8'ha3;
assign i_Gtable[121] = 8'ha4;
assign i_Gtable[122] = 8'ha5;
assign i_Gtable[123] = 8'ha6;
assign i_Gtable[124] = 8'ha6;
assign i_Gtable[125] = 8'ha7;
assign i_Gtable[126] = 8'ha8;
assign i_Gtable[127] = 8'ha9;
assign i_Gtable[128] = 8'haa;
assign i_Gtable[129] = 8'haa;
assign i_Gtable[130] = 8'hab;
assign i_Gtable[131] = 8'hac;
assign i_Gtable[132] = 8'had;
assign i_Gtable[133] = 8'had;
assign i_Gtable[134] = 8'hae;
assign i_Gtable[135] = 8'haf;
assign i_Gtable[136] = 8'hb0;
assign i_Gtable[137] = 8'hb0;
assign i_Gtable[138] = 8'hb1;
assign i_Gtable[139] = 8'hb2;
assign i_Gtable[140] = 8'hb3;
assign i_Gtable[141] = 8'hb3;
assign i_Gtable[142] = 8'hb4;
assign i_Gtable[143] = 8'hb5;
assign i_Gtable[144] = 8'hb6;
assign i_Gtable[145] = 8'hb6;
assign i_Gtable[146] = 8'hb7;
assign i_Gtable[147] = 8'hb8;
assign i_Gtable[148] = 8'hb9;
assign i_Gtable[149] = 8'hb9;
assign i_Gtable[150] = 8'hba;
assign i_Gtable[151] = 8'hbb;
assign i_Gtable[152] = 8'hbc;
assign i_Gtable[153] = 8'hbc;
assign i_Gtable[154] = 8'hbd;
assign i_Gtable[155] = 8'hbe;
assign i_Gtable[156] = 8'hbe;
assign i_Gtable[157] = 8'hbf;
assign i_Gtable[158] = 8'hc0;
assign i_Gtable[159] = 8'hc1;
assign i_Gtable[160] = 8'hc1;
assign i_Gtable[161] = 8'hc2;
assign i_Gtable[162] = 8'hc3;
assign i_Gtable[163] = 8'hc3;
assign i_Gtable[164] = 8'hc4;
assign i_Gtable[165] = 8'hc5;
assign i_Gtable[166] = 8'hc6;
assign i_Gtable[167] = 8'hc6;
assign i_Gtable[168] = 8'hc7;
assign i_Gtable[169] = 8'hc8;
assign i_Gtable[170] = 8'hc8;
assign i_Gtable[171] = 8'hc9;
assign i_Gtable[172] = 8'hca;
assign i_Gtable[173] = 8'hca;
assign i_Gtable[174] = 8'hcb;
assign i_Gtable[175] = 8'hcc;
assign i_Gtable[176] = 8'hcd;
assign i_Gtable[177] = 8'hcd;
assign i_Gtable[178] = 8'hce;
assign i_Gtable[179] = 8'hcf;
assign i_Gtable[180] = 8'hcf;
assign i_Gtable[181] = 8'hd0;
assign i_Gtable[182] = 8'hd1;
assign i_Gtable[183] = 8'hd1;
assign i_Gtable[184] = 8'hd2;
assign i_Gtable[185] = 8'hd3;
assign i_Gtable[186] = 8'hd3;
assign i_Gtable[187] = 8'hd4;
assign i_Gtable[188] = 8'hd5;
assign i_Gtable[189] = 8'hd5;
assign i_Gtable[190] = 8'hd6;
assign i_Gtable[191] = 8'hd7;
assign i_Gtable[192] = 8'hd7;
assign i_Gtable[193] = 8'hd8;
assign i_Gtable[194] = 8'hd9;
assign i_Gtable[195] = 8'hd9;
assign i_Gtable[196] = 8'hda;
assign i_Gtable[197] = 8'hdb;
assign i_Gtable[198] = 8'hdb;
assign i_Gtable[199] = 8'hdc;
assign i_Gtable[200] = 8'hdd;
assign i_Gtable[201] = 8'hdd;
assign i_Gtable[202] = 8'hde;
assign i_Gtable[203] = 8'hde;
assign i_Gtable[204] = 8'hdf;
assign i_Gtable[205] = 8'he0;
assign i_Gtable[206] = 8'he0;
assign i_Gtable[207] = 8'he1;
assign i_Gtable[208] = 8'he2;
assign i_Gtable[209] = 8'he2;
assign i_Gtable[210] = 8'he3;
assign i_Gtable[211] = 8'he4;
assign i_Gtable[212] = 8'he4;
assign i_Gtable[213] = 8'he5;
assign i_Gtable[214] = 8'he6;
assign i_Gtable[215] = 8'he6;
assign i_Gtable[216] = 8'he7;
assign i_Gtable[217] = 8'he7;
assign i_Gtable[218] = 8'he8;
assign i_Gtable[219] = 8'he9;
assign i_Gtable[220] = 8'he9;
assign i_Gtable[221] = 8'hea;
assign i_Gtable[222] = 8'heb;
assign i_Gtable[223] = 8'heb;
assign i_Gtable[224] = 8'hec;
assign i_Gtable[225] = 8'hec;
assign i_Gtable[226] = 8'hed;
assign i_Gtable[227] = 8'hee;
assign i_Gtable[228] = 8'hee;
assign i_Gtable[229] = 8'hef;
assign i_Gtable[230] = 8'hef;
assign i_Gtable[231] = 8'hf0;
assign i_Gtable[232] = 8'hf1;
assign i_Gtable[233] = 8'hf1;
assign i_Gtable[234] = 8'hf2;
assign i_Gtable[235] = 8'hf3;
assign i_Gtable[236] = 8'hf3;
assign i_Gtable[237] = 8'hf4;
assign i_Gtable[238] = 8'hf4;
assign i_Gtable[239] = 8'hf5;
assign i_Gtable[240] = 8'hf6;
assign i_Gtable[241] = 8'hf6;
assign i_Gtable[242] = 8'hf7;
assign i_Gtable[243] = 8'hf7;
assign i_Gtable[244] = 8'hf8;
assign i_Gtable[245] = 8'hf9;
assign i_Gtable[246] = 8'hf9;
assign i_Gtable[247] = 8'hfa;
assign i_Gtable[248] = 8'hfa;
assign i_Gtable[249] = 8'hfb;
assign i_Gtable[250] = 8'hfc;
assign i_Gtable[251] = 8'hfc;
assign i_Gtable[252] = 8'hfd;
assign i_Gtable[253] = 8'hfd;
assign i_Gtable[254] = 8'hfe;
assign i_Gtable[255] = 8'hff;


endmodule
