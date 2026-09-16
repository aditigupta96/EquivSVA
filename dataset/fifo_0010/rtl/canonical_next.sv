module fifo_0010_canonical_next (
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

    reg [2:0] next_count;

    always @* begin
        if (flush) next_count = 3'd0;
        else if (!flush && push && !pop && (count < 3'd4)) next_count = count + 3'd1;
        else if (!flush && pop && !push && (count > 3'd0)) next_count = count - 3'd1;
        else next_count = count;
    end

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
