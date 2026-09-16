module fifo_0010_ternary_next (
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

    wire [2:0] next_count;

    assign next_count = (flush) ? (3'd0) : ((!flush && push && !pop && (count < 3'd4)) ? (count + 3'd1) : ((!flush && pop && !push && (count > 3'd0)) ? (count - 3'd1) : (count)));

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
