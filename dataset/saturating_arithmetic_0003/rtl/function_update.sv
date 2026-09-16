module saturating_arithmetic_0003_function_update (
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

    function automatic [2:0] compute_next_value_reg;
        input [2:0] current_value_reg;
        input [1:0] current_dir_reg;
        input clear;
        input inc;
        input dec;
        begin
            if (clear) compute_next_value_reg = 3'd3;
            else if (!clear && inc && !dec && (current_value_reg < 3'd6)) compute_next_value_reg = current_value_reg + 3'd1;
            else if (!clear && dec && !inc && (current_value_reg > 3'd1)) compute_next_value_reg = current_value_reg - 3'd1;
            else compute_next_value_reg = current_value_reg;
        end
    endfunction

    function automatic [1:0] compute_next_dir_reg;
        input [2:0] current_value_reg;
        input [1:0] current_dir_reg;
        input clear;
        input inc;
        input dec;
        begin
            if (clear) compute_next_dir_reg = 2'd0;
            else if (!clear && inc && !dec && (current_value_reg < 3'd6)) compute_next_dir_reg = 2'd1;
            else if (!clear && dec && !inc && (current_value_reg > 3'd1)) compute_next_dir_reg = 2'd2;
            else compute_next_dir_reg = current_dir_reg;
        end
    endfunction

    wire [2:0] next_value_reg;
    wire [1:0] next_dir_reg;

    assign next_value_reg = compute_next_value_reg(value_reg, dir_reg, clear, inc, dec);
    assign next_dir_reg = compute_next_dir_reg(value_reg, dir_reg, clear, inc, dec);

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
