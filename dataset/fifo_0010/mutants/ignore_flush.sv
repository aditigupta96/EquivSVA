module fifo_0010_mutant_ignore_flush (
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

    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd0;
        end
        else begin
            if (!flush && push && !pop && (count < 3'd4)) count <= count + 3'd1;
            else if (!flush && pop && !push && (count > 3'd0)) count <= count - 3'd1;
            else count <= count;
        end
    end

    assign empty = count == 3'd0;
    assign full = count == 3'd4;
    assign almost_full = count >= 3'd3;
endmodule
