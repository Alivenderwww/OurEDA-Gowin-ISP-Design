`ifndef __COLOR_SVH__
`define __COLOR_SVH__

`default_nettype wire

class Color #(
    int DEEPTH = 8
);

`ifdef DEBUG
  typedef struct {
    bit [DEEPTH - 1:0] red;
    bit [DEEPTH - 1:0] green;
    bit [DEEPTH - 1:0] blue;
  } color_t;
`else
  typedef struct packed {
    bit [DEEPTH - 1:0] red;
    bit [DEEPTH - 1:0] green;
    bit [DEEPTH - 1:0] blue;
  } color_t;
`endif

  // convert 3 color to Color
  static function automatic color_t f_fromRGB(bit [DEEPTH - 1 : 0] red, bit [DEEPTH - 1 : 0] green,
                                              bit [DEEPTH - 1 : 0] blue);
`ifdef DEBUG
    color_t _color;
    _color.red   = red;
    _color.green = green;
    _color.blue  = blue;
    return _color;
`else
    return {red, green, blue};
`endif
  endfunction

  // convert Bits to Color
  static function automatic color_t f_fromBits(bit [DEEPTH * 3 - 1 : 0] data);
`ifdef DEBUG
    color_t _color;
    _color.red   = data[DEEPTH*3-1-:DEEPTH];
    _color.green = data[DEEPTH*2-1-:DEEPTH];
    _color.blue  = data[DEEPTH*1-1-:DEEPTH];
    return _color;
`else
    return {data};
`endif
  endfunction

  // convert Color to Bits
  static function automatic bit [DEEPTH * 3 - 1 : 0] f_toBits(color_t color);
    return {color.red, color.green, color.blue};
  endfunction

endclass

typedef Color#(8) Color8;
typedef Color#(8)::color_t color8_t;

typedef Color#(12) Color12;
typedef Color#(12)::color_t color12_t;

typedef Color#(16) Color16;
typedef Color#(16)::color_t color16_t;

`endif
