module saturating_arithmetic_0010_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire inc,
    input  wire dec,
    output reg  [2:0] value,
    output wire at_zero,
    output wire at_max
);

    function automatic [2:0] compute_next_value;
        input [2:0] current;
        input clear;
        input inc;
        input dec;
        begin
            if (clear) compute_next_value = 3'd3;
            else if (!clear && inc && !dec && (current < 3'd7)) compute_next_value = current + 3'd1;
            else if (!clear && dec && !inc && (current > 3'd0)) compute_next_value = current - 3'd1;
            else compute_next_value = current;
        end
    endfunction

    wire [2:0] next_value;

    assign next_value = compute_next_value(value, clear, inc, dec);

    always @(posedge clk) begin
        if (rst)
            value <= 3'd3;
        else
            value <= next_value;
    end

    assign at_zero = value == 3'd0;
    assign at_max = value == 3'd7;
endmodule
