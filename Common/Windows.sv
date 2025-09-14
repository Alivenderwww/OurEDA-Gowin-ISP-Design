module Windows #(
parameter DATA_WIDTH = 16,
parameter WINDOWS_WIDTH = 3,
parameter WINDOWS_ANCHOR_X = 1,//禁止大于WINDOWS_WIDTH-1
parameter WINDOWS_ANCHOR_Y = 1 //禁止大于WINDOWS_WIDTH-1
)(
    // 基本信号
    input wire clk,
    input wire reset,
    //  数据线
    input wire [DATA_WIDTH - 1:0] in_data,
    input wire [7:0] in_user,
    output reg [DATA_WIDTH - 1:0] out_data [WINDOWS_WIDTH*WINDOWS_WIDTH],   // 数据输出线
    output wire [7:0] out_user,
    //  有效信号
    input wire in_valid,    // 上一模块输出数据有效
    output wire out_valid,   // 当前模块输出数据有效
    //  准备信号 Windows模块无法停止，因此默认不处理准备信号
    input wire in_ready,
    output wire out_ready
);

assign out_ready = 1'b1;

reg [DATA_WIDTH - 1:0] regx_in_data[WINDOWS_WIDTH-1];
wire [DATA_WIDTH - 1:0] regx_out_data[WINDOWS_WIDTH-1];
reg [7:0] regx_in_user[WINDOWS_WIDTH-1];
wire [7:0] regx_out_user[WINDOWS_WIDTH-1];
reg [WINDOWS_WIDTH - 2:0] regx_in_valid;
wire [WINDOWS_WIDTH - 2:0] regx_out_valid;

reg [DATA_WIDTH - 1:0] data_out_shift[WINDOWS_WIDTH-1][2*(WINDOWS_WIDTH-1)];
reg [7:0] user_out_shift[WINDOWS_WIDTH-1][2*(WINDOWS_WIDTH-1)];

reg [7:0] out_user_windows[WINDOWS_WIDTH*WINDOWS_WIDTH];
assign out_user = out_user_windows[(WINDOWS_WIDTH*WINDOWS_ANCHOR_Y) + WINDOWS_ANCHOR_X];

/*              outdata[x]:
SHIFT_REG1  ->  0 3 6 . .
SHIFT_REG0  ->  1 4 7 . .
   in_data  ->  2 5 8 . .
                . . .
                . . .
*/

reg out_valid_output;
reg firstframedone;
always @(posedge clk) begin
    if(reset) firstframedone <= 0;
    else if(out_user == 1'b1) firstframedone <= 1;
    else firstframedone <= firstframedone;
end
always @(posedge clk) begin
    if(reset) out_valid_output <= 0;
    else out_valid_output <= regx_out_valid[WINDOWS_WIDTH-2];
end
assign out_valid = out_valid_output & (firstframedone || out_user);

integer i,j;
always @(posedge clk) begin
    if(reset)begin
        for(i=0;i<WINDOWS_WIDTH*WINDOWS_WIDTH;i=i+1) out_data[i] <= 0;
        for(i=0;i<WINDOWS_WIDTH*WINDOWS_WIDTH;i=i+1) out_user_windows[i] <= 0;
    end else if(regx_out_valid[WINDOWS_WIDTH-2])begin
        for(i=0;i<WINDOWS_WIDTH;i=i+1) begin
            for(j=0;j<WINDOWS_WIDTH;j=j+1) begin
                if(i==WINDOWS_WIDTH-1) begin
                    if(j==0) out_data[(WINDOWS_WIDTH*i)+j] <= regx_out_data[WINDOWS_WIDTH-2];
                    else out_data[(WINDOWS_WIDTH*i)+j] <= data_out_shift[j-1][2*j-1];
                end
                else out_data[(WINDOWS_WIDTH*i)+j] <= out_data[(WINDOWS_WIDTH*(i+1))+j];
            end
        end
        for(i=0;i<WINDOWS_WIDTH;i=i+1) begin
            for(j=0;j<WINDOWS_WIDTH;j=j+1) begin
                if(i==WINDOWS_WIDTH-1) begin
                    if(j==0) out_user_windows[(WINDOWS_WIDTH*i)+j] <= regx_out_user[WINDOWS_WIDTH-2];
                    else out_user_windows[(WINDOWS_WIDTH*i)+j] <= user_out_shift[j-1][2*j-1];
                end
                else out_user_windows[(WINDOWS_WIDTH*i)+j] <= out_user_windows[(WINDOWS_WIDTH*(i+1))+j];
            end
        end
    end else begin
        for(i=0;i<WINDOWS_WIDTH*WINDOWS_WIDTH-1;i=i+1) out_data[i] <= out_data[i];
        for(i=0;i<WINDOWS_WIDTH*WINDOWS_WIDTH-1;i=i+1) out_user_windows[i] <= out_user_windows[i];
    end
end

always @(posedge clk) begin
    if(reset) for(i=0;i<WINDOWS_WIDTH-1;i=i+1) for(j=0;j<WINDOWS_WIDTH-1;j=j+1) begin
        data_out_shift[i][j] <= 0;
        user_out_shift[i][j] <= 0;
    end else for(i=0;i<WINDOWS_WIDTH-1;i=i+1) begin
        for(j=0;j<2*(WINDOWS_WIDTH-1);j=j+1) begin
            if(i==WINDOWS_WIDTH-2 && j==0) data_out_shift[i][j] <= in_data;
            else if(j==0) data_out_shift[i][j] <= regx_out_data[(WINDOWS_WIDTH-2-i)-1];
            else data_out_shift[i][j] <= data_out_shift[i][j-1];

            if(i==WINDOWS_WIDTH-2 && j==0) user_out_shift[i][j] <= in_user;
            else if(j==0) user_out_shift[i][j] <= regx_out_user[(WINDOWS_WIDTH-2-i)-1];
            else user_out_shift[i][j] <= user_out_shift[i][j-1];
        end
    end
end

always @(*) begin
    for(i=0;i<WINDOWS_WIDTH-1;i=i+1)begin
        if(i == 0) regx_in_data[i] = in_data;
        else regx_in_data[i] = regx_out_data[i-1];
    end
    for(i=0;i<WINDOWS_WIDTH-1;i=i+1)begin
        if(i == 0) regx_in_user[i] = in_user;
        else regx_in_user[i] = regx_out_user[i-1];
    end
    for(i=0;i<WINDOWS_WIDTH-1;i=i+1)begin
        if(i == 0) regx_in_valid[i] = in_valid;
        else regx_in_valid[i] = regx_out_valid[i-1];
    end
end

generate 
  genvar o;
    for(o = 0; o < WINDOWS_WIDTH - 1; o = o + 1'b1) begin:shift_register
        SHIFT_REGISTER #(
        .DATA_WIDTH(DATA_WIDTH),
        .IFOUTIMME(1'b1)
        )shift_registerx(
          .clk      (clk),
          .reset    (reset),
          .in_data  (regx_in_data[o]),
          .in_user  (regx_in_user[o]),
          .out_data (regx_out_data[o]),
          .out_user (regx_out_user[o]),
          .in_valid (regx_in_valid[o]),
          .out_valid(regx_out_valid[o])
        );
      end
endgenerate

endmodule