module saturating_arithmetic_0007_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire dec,
    input  wire restore,
    output reg  [2:0] value,
    output wire at_floor
);

    always @(posedge clk) begin
        if (rst) begin
            value <= 3'd7;
        end
        else begin
            if (restore) value <= 3'd7;
            else if (!restore && dec && (value > 3'd2)) value <= value - 3'd1;
            else value <= value;
        end
    end

    assign at_floor = value == 3'd2;
endmodule
