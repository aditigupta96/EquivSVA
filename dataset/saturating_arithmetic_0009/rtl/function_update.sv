module saturating_arithmetic_0009_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear_history,
    input  wire inc,
    input  wire dec,
    output wire [2:0] value,
    output wire hit_low,
    output wire hit_high
);

    reg [2:0] value_reg;
    reg low_reg;
    reg high_reg;

    function automatic [2:0] compute_next_value_reg;
        input [2:0] current_value_reg;
        input current_low_reg;
        input current_high_reg;
        input clear_history;
        input inc;
        input dec;
        begin
            if (inc && !dec && (current_value_reg < 3'd6)) compute_next_value_reg = current_value_reg + 3'd1;
            else if (dec && !inc && (current_value_reg > 3'd1)) compute_next_value_reg = current_value_reg - 3'd1;
            else compute_next_value_reg = current_value_reg;
        end
    endfunction

    function automatic compute_next_low_reg;
        input [2:0] current_value_reg;
        input current_low_reg;
        input current_high_reg;
        input clear_history;
        input inc;
        input dec;
        begin
            if (clear_history) compute_next_low_reg = 1'b0;
            else if (dec && !inc && (current_value_reg == 3'd2)) compute_next_low_reg = 1'b1;
            else compute_next_low_reg = current_low_reg;
        end
    endfunction

    function automatic compute_next_high_reg;
        input [2:0] current_value_reg;
        input current_low_reg;
        input current_high_reg;
        input clear_history;
        input inc;
        input dec;
        begin
            if (clear_history) compute_next_high_reg = 1'b0;
            else if (inc && !dec && (current_value_reg == 3'd5)) compute_next_high_reg = 1'b1;
            else compute_next_high_reg = current_high_reg;
        end
    endfunction

    wire [2:0] next_value_reg;
    wire next_low_reg;
    wire next_high_reg;

    assign next_value_reg = compute_next_value_reg(value_reg, low_reg, high_reg, clear_history, inc, dec);
    assign next_low_reg = compute_next_low_reg(value_reg, low_reg, high_reg, clear_history, inc, dec);
    assign next_high_reg = compute_next_high_reg(value_reg, low_reg, high_reg, clear_history, inc, dec);

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 3'd3;
            low_reg <= 1'b0;
            high_reg <= 1'b0;
        end
        else begin
            value_reg <= next_value_reg;
            low_reg <= next_low_reg;
            high_reg <= next_high_reg;
        end
    end

    assign value = value_reg;
    assign hit_low = low_reg;
    assign hit_high = high_reg;
endmodule
