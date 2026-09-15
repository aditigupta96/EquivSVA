module fifo_0005_ternary_next (
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

    wire [1:0] next_head_reg;
    wire [1:0] next_tail_reg;
    wire [1:0] next_count_reg;

    assign next_head_reg = (push && (count_reg == 2'd0)) ? (din) : ((push && pop && (count_reg == 2'd1)) ? (din) : ((pop && (count_reg == 2'd2)) ? (tail_reg) : (head_reg)));
    assign next_tail_reg = (push && !pop && (count_reg == 2'd1)) ? (din) : (tail_reg);
    assign next_count_reg = (push && (count_reg < 2'd2) && !(pop && (count_reg > 2'd0))) ? (count_reg + 2'd1) : ((pop && (count_reg > 2'd0) && !(push && (count_reg < 2'd2))) ? (count_reg - 2'd1) : (count_reg));

    always @(posedge clk) begin
        if (rst) begin
            head_reg <= 2'd0;
            tail_reg <= 2'd0;
            count_reg <= 2'd0;
        end
        else begin
            head_reg <= next_head_reg;
            tail_reg <= next_tail_reg;
            count_reg <= next_count_reg;
        end
    end

    assign dout = head_reg;
    assign count = count_reg;
    assign empty = count_reg == 2'd0;
    assign full = count_reg == 2'd2;
    assign ready = count_reg < 2'd2;
endmodule
