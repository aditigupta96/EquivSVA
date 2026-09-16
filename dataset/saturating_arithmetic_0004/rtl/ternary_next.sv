module saturating_arithmetic_0004_ternary_next (
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

    wire [3:0] next_value_reg;
    wire next_overflow_reg;

    assign next_value_reg = (clear) ? (4'd0) : ((!clear && add && (value_reg < 4'd3)) ? (value_reg + 4'd1) : (value_reg));
    assign next_overflow_reg = (clear) ? (1'b0) : ((!clear && add && (value_reg == 4'd3)) ? (1'b1) : (overflow_reg));

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
