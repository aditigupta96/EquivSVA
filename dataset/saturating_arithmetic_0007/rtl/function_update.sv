module saturating_arithmetic_0007_function_update (
    input  wire clk,
    input  wire rst,
    input  wire dec,
    input  wire restore,
    output reg  [2:0] value,
    output wire at_floor
);

    function automatic [2:0] compute_next_value;
        input [2:0] current;
        input dec;
        input restore;
        begin
            if (restore) compute_next_value = 3'd7;
            else if (!restore && dec && (current > 3'd2)) compute_next_value = current - 3'd1;
            else compute_next_value = current;
        end
    endfunction

    wire [2:0] next_value;

    assign next_value = compute_next_value(value, dec, restore);

    always @(posedge clk) begin
        if (rst)
            value <= 3'd7;
        else
            value <= next_value;
    end

    assign at_floor = value == 3'd2;
endmodule
