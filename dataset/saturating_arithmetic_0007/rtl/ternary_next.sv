module saturating_arithmetic_0007_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire dec,
    input  wire restore,
    output reg  [2:0] value,
    output wire at_floor
);

    wire [2:0] next_value;

    assign next_value = (restore) ? (3'd7) : ((!restore && dec && (value > 3'd2)) ? (value - 3'd1) : (value));

    always @(posedge clk) begin
        if (rst)
            value <= 3'd7;
        else
            value <= next_value;
    end

    assign at_floor = value == 3'd2;
endmodule
