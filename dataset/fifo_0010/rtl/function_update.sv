module fifo_0010_function_update (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    input  wire flush,
    output reg  [2:0] count,
    output wire empty,
    output wire full,
    output wire almost_full
);

    function automatic [2:0] compute_next_count;
        input [2:0] current;
        input push;
        input pop;
        input flush;
        begin
            if (flush) compute_next_count = 3'd0;
            else if (!flush && push && !pop && (current < 3'd4)) compute_next_count = current + 3'd1;
            else if (!flush && pop && !push && (current > 3'd0)) compute_next_count = current - 3'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [2:0] next_count;

    assign next_count = compute_next_count(count, push, pop, flush);

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign empty = count == 3'd0;
    assign full = count == 3'd4;
    assign almost_full = count >= 3'd3;
endmodule
