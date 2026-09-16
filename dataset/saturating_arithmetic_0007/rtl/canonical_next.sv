module saturating_arithmetic_0007_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire dec,
    input  wire restore,
    output reg  [2:0] value,
    output wire at_floor
);

    reg [2:0] next_value;

    always @* begin
        if (restore) next_value = 3'd7;
        else if (!restore && dec && (value > 3'd2)) next_value = value - 3'd1;
        else next_value = value;
    end

    always @(posedge clk) begin
        if (rst)
            value <= 3'd7;
        else
            value <= next_value;
    end

    assign at_floor = value == 3'd2;
endmodule
