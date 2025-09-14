module Parallel_sorting #(
parameter DATA_WIDTH = 16,        // 输入/输出数据位宽
parameter DATA_NUM = 16           // 输入/输出数据位宽
)(
    input wire clk,
    input wire reset,
    
    input wire [DATA_WIDTH - 1:0] in_data [DATA_NUM],
    output reg [DATA_WIDTH - 1:0] out_data[DATA_NUM]
);

localparam LATENCY = 4;
reg [DATA_WIDTH-1:0] data_cache0[DATA_NUM];
reg [DATA_WIDTH-1:0] data_cache1[DATA_NUM];
reg [DATA_WIDTH-1:0] data_sort[DATA_NUM];
reg [DATA_WIDTH-1:0] score[DATA_NUM];
reg [DATA_NUM-1:0] score_sum[DATA_NUM];

integer i,o;
always @(posedge clk) begin
    if(reset) begin
        for(i=0;i<DATA_NUM;i=i+1) data_cache0[i] <= 0;
        for(i=0;i<DATA_NUM;i=i+1) data_cache1[i] <= 0;
        for(i=0;i<DATA_NUM;i=i+1) data_sort[i] <= 0;
    end else begin

        for(i=0;i<DATA_NUM;i=i+1) data_cache0[i] <= in_data[i];

        for(i=0;i<DATA_NUM;i=i+1) data_cache1[i] <= data_cache0[i];
        for (i=0;i<DATA_NUM;i=i+1) begin
            for (o=0;o<DATA_NUM;o=o+1) begin
                if(data_cache0[i] > data_cache0[o]) score[i][o] <= 1;
                else if(data_cache0[i] == data_cache0[o]) score[i][o] <= (i<=o);
                else score[i][o] <= 0;
            end
        end

        for(i=0;i<DATA_NUM;i=i+1) data_sort[score_sum[i]-1] <= data_cache1[i];

        for(i=0;i<DATA_NUM;i=i+1) out_data[i] <= data_sort[i];
    end
end

always @(*) begin
    for (i=0;i<DATA_NUM;i=i+1) begin
        score_sum[i] = 0;
        for (o=0;o<DATA_NUM;o=o+1) score_sum[i] = score_sum[i] + score[i][o];
    end
end

endmodule