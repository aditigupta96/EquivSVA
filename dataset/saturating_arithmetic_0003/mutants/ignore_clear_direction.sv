module saturating_arithmetic_0003_mutant_ignore_clear_direction (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire inc,
    input  wire dec,
    output wire [2:0] value,
    output wire last_up,
    output wire last_down,
    output wire at_low,
    output wire at_high
);

    reg [2:0] value_reg;
    reg [1:0] dir_reg;

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 3'd3;
            dir_reg <= 2'd0;
        end
        else begin
            if (clear) value_reg <= 3'd3;
            else if (!clear && inc && !dec && (value_reg < 3'd6)) value_reg <= value_reg + 3'd1;
            else if (!clear && dec && !inc && (value_reg > 3'd1)) value_reg <= value_reg - 3'd1;
            else value_reg <= value_reg;
            if (!clear && inc && !dec && (value_reg < 3'd6)) dir_reg <= 2'd1;
            else if (!clear && dec && !inc && (value_reg > 3'd1)) dir_reg <= 2'd2;
            else dir_reg <= dir_reg;
        end
    end

    assign value = value_reg;
    assign last_up = dir_reg == 2'd1;
    assign last_down = dir_reg == 2'd2;
    assign at_low = value_reg == 3'd1;
    assign at_high = value_reg == 3'd6;
endmodule
