module counter_0003_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    input  wire down,
    output reg  [1:0] count,
    output wire at_min,
    output wire at_max
);

    wire [1:0] next_count;

    assign next_count = (clear) ? (2'd0) : ((enable && down && (count > 2'd0)) ? (count - 2'd1) : ((enable && !down && (count < 2'd3)) ? (count + 2'd1) : (count)));

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign at_min = count == 2'd0;
    assign at_max = count == 2'd3;
endmodule
