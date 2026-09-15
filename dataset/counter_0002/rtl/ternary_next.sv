module counter_0002_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [1:0] count,
    output wire is_zero
);

    wire [1:0] next_count;

    assign next_count = (clear) ? (2'd0) : ((enable && (count == 2'd3)) ? (2'd0) : ((enable && (count < 2'd3)) ? (count + 2'd1) : (count)));

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign is_zero = count == 2'd0;
endmodule
