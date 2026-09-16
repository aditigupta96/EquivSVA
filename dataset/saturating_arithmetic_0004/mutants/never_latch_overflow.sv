module saturating_arithmetic_0004_mutant_never_latch_overflow (
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

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 4'd0;
            overflow_reg <= 1'b0;
        end
        else begin
            if (clear) value_reg <= 4'd0;
            else if (!clear && add && (value_reg < 4'd15)) value_reg <= value_reg + 4'd1;
            else value_reg <= value_reg;
            if (clear) overflow_reg <= 1'b0;
            else overflow_reg <= overflow_reg;
        end
    end

    assign value = value_reg;
    assign overflowed = overflow_reg;
    assign at_max = value_reg == 4'd15;
endmodule
