module saturating_arithmetic_0010_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire inc,
    input  wire dec,
    output reg  [2:0] value,
    output wire at_zero,
    output wire at_max
);

    reg [2:0] next_value;

    always @* begin
        if (clear) next_value = 3'd3;
        else if (!clear && inc && !dec && (value < 3'd7)) next_value = value + 3'd1;
        else if (!clear && dec && !inc && (value > 3'd0)) next_value = value - 3'd1;
        else next_value = value;
    end

    always @(posedge clk) begin
        if (rst)
            value <= 3'd3;
        else
            value <= next_value;
    end

    assign at_zero = value == 3'd0;
    assign at_max = value == 3'd7;
endmodule
