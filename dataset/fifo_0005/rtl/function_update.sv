module fifo_0005_function_update (
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

    function automatic [1:0] compute_next_head_reg;
        input [1:0] current_head_reg;
        input [1:0] current_tail_reg;
        input [1:0] current_count_reg;
        input push;
        input pop;
        input [1:0] din;
        begin
            if (push && (current_count_reg == 2'd0)) compute_next_head_reg = din;
            else if (push && pop && (current_count_reg == 2'd1)) compute_next_head_reg = din;
            else if (pop && (current_count_reg == 2'd2)) compute_next_head_reg = current_tail_reg;
            else compute_next_head_reg = current_head_reg;
        end
    endfunction

    function automatic [1:0] compute_next_tail_reg;
        input [1:0] current_head_reg;
        input [1:0] current_tail_reg;
        input [1:0] current_count_reg;
        input push;
        input pop;
        input [1:0] din;
        begin
            if (push && !pop && (current_count_reg == 2'd1)) compute_next_tail_reg = din;
            else compute_next_tail_reg = current_tail_reg;
        end
    endfunction

    function automatic [1:0] compute_next_count_reg;
        input [1:0] current_head_reg;
        input [1:0] current_tail_reg;
        input [1:0] current_count_reg;
        input push;
        input pop;
        input [1:0] din;
        begin
            if (push && (current_count_reg < 2'd2) && !(pop && (current_count_reg > 2'd0))) compute_next_count_reg = current_count_reg + 2'd1;
            else if (pop && (current_count_reg > 2'd0) && !(push && (current_count_reg < 2'd2))) compute_next_count_reg = current_count_reg - 2'd1;
            else compute_next_count_reg = current_count_reg;
        end
    endfunction

    wire [1:0] next_head_reg;
    wire [1:0] next_tail_reg;
    wire [1:0] next_count_reg;

    assign next_head_reg = compute_next_head_reg(head_reg, tail_reg, count_reg, push, pop, din);
    assign next_tail_reg = compute_next_tail_reg(head_reg, tail_reg, count_reg, push, pop, din);
    assign next_count_reg = compute_next_count_reg(head_reg, tail_reg, count_reg, push, pop, din);

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
