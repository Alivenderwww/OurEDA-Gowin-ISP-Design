`ifndef __VECTOR_SVH__
`define __VECTOR_SVH__

`include "common"

`define Typedef_Vector(Name, DataType, DataDeepth, SizeDeepth) \
`define Name Vector#(Name, DataType, DataDeepth, SizeDeepth) \
`ifdef DEBUG \
  typedef struct { \
    DataType data[DataDeepth]; \
    bit [SizeDeepth - 1 : 0] size; \
  } \
`else \
  typedef struct packed { \
    DataType [DataDeepth:0] data; \
    bit [SizeDeepth - 1 : 0] size; \
  } \
`endif

class Vector #(
    type ARRAY_TYPE,
    type BASIC_TYPE,
    int  DATA_DEEPTH = 8,
    int  SIZE_DEEPTH = 8
);

  // Get the size of Vector
  static function automatic bit [SIZE_DEEPTH - 1 : 0] f_getSize(ARRAY_TYPE _vector);
    return _vector.size;
  endfunction  //automatic

  // Fill Vector with data, size will be full
  static function automatic ARRAY_TYPE f_fill(BASIC_TYPE data);
`ifdef DEBUG
    ARRAY_TYPE _vector;
    for (int i = 0; i < DATA_DEEPTH; ++i) _vector.data[i] = data;
    _vector.size = DATA_DEEPTH;
    return _vector;
`else
    return {{DATA_DEEPTH{data}}, DATA_DEEPTH};
`endif
  endfunction  //automatic

  // Clear Vector with data, size will be empty
  static function automatic ARRAY_TYPE f_clearWith(BASIC_TYPE data);
`ifdef DEBUG
    ARRAY_TYPE _vector;
    for (int i = 0; i < DATA_DEEPTH; ++i) _vector.data[i] = data;
    _vector.size = 0;
    return _vector;
`else
    return {{DATA_DEEPTH{data}}, {SIZE_DEEPTH{1'b0}}};
`endif
  endfunction

  // Push data into front Vector
  static function automatic ARRAY_TYPE f_pushFront(BASIC_TYPE data, ARRAY_TYPE _vector);
`ifdef DEBUG
    for (int i = 1; i < DATA_DEEPTH; ++i) _vector.data[i] = _vector.data[i-1];
`else
    _vector.data = _vector.data >> DATA_DEEPTH;
`endif
    _vector.data[0] = data;
    _vector.size = _vector.size + 1;
    return _vector;
  endfunction  //automatic

  // Get the last data of the Vector
  static function automatic BASIC_TYPE f_getBack(ARRAY_TYPE _vector);
    return _vector.data[DATA_DEEPTH-1];
  endfunction  //automatic

endclass

`endif
