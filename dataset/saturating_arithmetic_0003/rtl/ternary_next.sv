module saturating_arithmetic_0003_ternary_next (
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

    wire [2:0] next_value_reg;
    wire [1:0] next_dir_reg;

    assign next_value_reg = (clear) ? (3'd3) : ((!clear && inc && !dec && (value_reg < 3'd6)) ? (value_reg + 3'd1) : ((!clear && dec && !inc && (value_reg > 3'd1)) ? (value_reg - 3'd1) : (value_reg)));
    assign next_dir_reg = (clear) ? (2'd0) : ((!clear && inc && !dec && (value_reg < 3'd6)) ? (2'd1) : ((!clear && dec && !inc && (value_reg > 3'd1)) ? (2'd2) : (dir_reg)));

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 3'd3;
            dir_reg <= 2'd0;
        end
        else begin
            value_reg <= next_value_reg;
            dir_reg <= next_dir_reg;
        end
    end

    assign value = value_reg;
    assign last_up = dir_reg == 2'd1;
    assign last_down = dir_reg == 2'd2;
    assign at_low = value_reg == 3'd1;
    assign at_high = value_reg == 3'd6;
endmodule
