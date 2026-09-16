module saturating_arithmetic_0003_canonical_next (
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

    reg [2:0] next_value_reg;
    reg [1:0] next_dir_reg;

    always @* begin
        if (clear) next_value_reg = 3'd3;
        else if (!clear && inc && !dec && (value_reg < 3'd6)) next_value_reg = value_reg + 3'd1;
        else if (!clear && dec && !inc && (value_reg > 3'd1)) next_value_reg = value_reg - 3'd1;
        else next_value_reg = value_reg;
        if (clear) next_dir_reg = 2'd0;
        else if (!clear && inc && !dec && (value_reg < 3'd6)) next_dir_reg = 2'd1;
        else if (!clear && dec && !inc && (value_reg > 3'd1)) next_dir_reg = 2'd2;
        else next_dir_reg = dir_reg;
    end

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
