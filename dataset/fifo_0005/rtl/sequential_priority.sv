module fifo_0005_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    input  wire [1:0] din,
    output wire [1:0] dout,
    output wire [1:0] count,
    output wire empty,
    output wire full,
    output wire ready
);

    reg [1:0] head_reg;
    reg [1:0] tail_reg;
    reg [1:0] count_reg;

    always @(posedge clk) begin
        if (rst) begin
            head_reg <= 2'd0;
            tail_reg <= 2'd0;
            count_reg <= 2'd0;
        end
        else begin
            if (push && (count_reg == 2'd0)) head_reg <= din;
            else if (push && pop && (count_reg == 2'd1)) head_reg <= din;
            else if (pop && (count_reg == 2'd2)) head_reg <= tail_reg;
            else head_reg <= head_reg;
            if (push && !pop && (count_reg == 2'd1)) tail_reg <= din;
            else tail_reg <= tail_reg;
            if (push && (count_reg < 2'd2) && !(pop && (count_reg > 2'd0))) count_reg <= count_reg + 2'd1;
            else if (pop && (count_reg > 2'd0) && !(push && (count_reg < 2'd2))) count_reg <= count_reg - 2'd1;
            else count_reg <= count_reg;
        end
    end

    assign dout = head_reg;
    assign count = count_reg;
    assign empty = count_reg == 2'd0;
    assign full = count_reg == 2'd2;
    assign ready = count_reg < 2'd2;
endmodule
