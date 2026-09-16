module saturating_arithmetic_0010_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire inc,
    input  wire dec,
    output reg  [2:0] value,
    output wire at_zero,
    output wire at_max
);

    wire [2:0] next_value;

    assign next_value = (clear) ? (3'd3) : ((!clear && inc && !dec && (value < 3'd7)) ? (value + 3'd1) : ((!clear && dec && !inc && (value > 3'd0)) ? (value - 3'd1) : (value)));

    always @(posedge clk) begin
        if (rst)
            value <= 3'd3;
        else
            value <= next_value;
    end

    assign at_zero = value == 3'd0;
    assign at_max = value == 3'd7;
endmodule
