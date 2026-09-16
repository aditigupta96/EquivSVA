module saturating_arithmetic_0001_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire add,
    output reg  [2:0] value,
    output wire at_max
);

    function automatic [2:0] compute_next_value;
        input [2:0] current;
        input clear;
        input add;
        begin
            if (clear) compute_next_value = 3'd0;
            else if (add && (current < 3'd7)) compute_next_value = current + 3'd1;
            else compute_next_value = current;
        end
    endfunction

    wire [2:0] next_value;

    assign next_value = compute_next_value(value, clear, add);

    always @(posedge clk) begin
        if (rst)
            value <= 3'd0;
        else
            value <= next_value;
    end

    assign at_max = value == 3'd7;
endmodule
