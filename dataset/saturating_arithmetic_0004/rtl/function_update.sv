module saturating_arithmetic_0004_function_update (
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

    function automatic [3:0] compute_next_value_reg;
        input [3:0] current_value_reg;
        input current_overflow_reg;
        input clear;
        input add;
        begin
            if (clear) compute_next_value_reg = 4'd0;
            else if (!clear && add && (current_value_reg < 4'd15)) compute_next_value_reg = current_value_reg + 4'd1;
            else compute_next_value_reg = current_value_reg;
        end
    endfunction

    function automatic compute_next_overflow_reg;
        input [3:0] current_value_reg;
        input current_overflow_reg;
        input clear;
        input add;
        begin
            if (clear) compute_next_overflow_reg = 1'b0;
            else if (!clear && add && (current_value_reg == 4'd15)) compute_next_overflow_reg = 1'b1;
            else compute_next_overflow_reg = current_overflow_reg;
        end
    endfunction

    wire [3:0] next_value_reg;
    wire next_overflow_reg;

    assign next_value_reg = compute_next_value_reg(value_reg, overflow_reg, clear, add);
    assign next_overflow_reg = compute_next_overflow_reg(value_reg, overflow_reg, clear, add);

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
    assign at_max = value_reg == 4'd15;
endmodule
