`ifndef __COMMON_SVH__
`define __COMMON_SVH__

`default_nettype wire


package common;

  typedef bit [63:0] uint64_t;
  typedef bit [31:0] uint32_t;
  typedef bit [15:0] uint16_t;
  typedef bit [7:0] uint8_t;

  typedef uint32_t uint;

  typedef bit bool;
  localparam bit TRUE = 1'b1;
  localparam bit FALSE = 1'b0;

  class Array #(
      type T,
      uint64_t LENGTH = 0
  );
    typedef T array_t[LENGTH];

    // Fill all array with data
    static function automatic array_t f_fill(T data);
      array_t _array = '{default: data};
      return _array;
    endfunction

    // right shift and replace first data
    static function automatic array_t f_pushFront(array_t array, T data);
      array_t _array;
      foreach (_array[i]) begin
        if (i != 0) begin
          _array[i] = array[i-1];
        end
      end
      _array[0] = data;
      return _array;
    endfunction

    // left shift and replace last data
    static function automatic array_t f_pushBack(array_t array, T data);
      array_t _array;
      foreach (_array[i]) begin
        if (i != LENGTH - 1) begin
          _array[i] = array[i+1];
        end
      end
      _array[LENGTH-1] = data;
      return _array;
    endfunction

    // get the last data
    static function automatic T f_getBack(array_t array);
      return array[LENGTH-1];
    endfunction

  endclass

endpackage

`endif
