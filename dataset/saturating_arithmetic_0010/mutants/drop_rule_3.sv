module saturating_arithmetic_0010_mutant_drop_rule_3 (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire inc,
    input  wire dec,
    output reg  [2:0] value,
    output wire at_zero,
    output wire at_max
);

    always @(posedge clk) begin
        if (rst) begin
            value <= 3'd3;
        end
        else begin
            if (clear) value <= 3'd3;
            else if (!clear && inc && !dec && (value < 3'd7)) value <= value + 3'd1;
            else value <= value;
        end
    end

    assign at_zero = value == 3'd0;
    assign at_max = value == 3'd7;
endmodule
