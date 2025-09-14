`default_nettype none

`include "common"

module common_tb
  import common::*;
();

  uint64_t test_64 = 64'hFFFF;
  uint32_t test_32 = 32'd9999;
  uint16_t test_16 = 16'h1111;
  uint8_t test_8 = 8'b10101010;
  bool test_bool = TRUE;

  uint8_t array[8] = '{default: 8'hFA};
  typedef Array#(
      .T(uint8_t),
      .LENGTH(8)
  ) my_array;
  typedef Array#(uint8_t, 8)::array_t array_t;
  // Array #(uint8_t, 8)::array_t test;
  array_t test_array;

  initial begin
    #10;
    array = my_array::f_fill(8'h00);
    #10;
    for (int i = 0; i < 8; ++i) begin
      array = my_array::f_pushFront(array, i);
      #10;
    end
    #10;
    $finish();
  end


endmodule
