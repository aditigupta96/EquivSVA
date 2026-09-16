module saturating_arithmetic_0004_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire add,
    output wire [3:0] value,
    output wire overflowed,
    output wire at_max
);

    reg [3:0] value_reg;
    reg overflow_reg;

    reg [3:0] next_value_reg;
    reg next_overflow_reg;

    always @* begin
        if (clear) next_value_reg = 4'd0;
        else if (!clear && add && (value_reg < 4'd3)) next_value_reg = value_reg + 4'd1;
        else next_value_reg = value_reg;
        if (clear) next_overflow_reg = 1'b0;
        else if (!clear && add && (value_reg == 4'd3)) next_overflow_reg = 1'b1;
        else next_overflow_reg = overflow_reg;
    end

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 4'd0;
            overflow_reg <= 1'b0;
        end
        else begin
            value_reg <= next_value_reg;
            overflow_reg <= next_overflow_reg;
        end
    end

    assign value = value_reg;
    assign overflowed = overflow_reg;
    assign at_max = value_reg == 4'd3;
endmodule
