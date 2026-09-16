module saturating_arithmetic_0001_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire add,
    output reg  [2:0] value,
    output wire at_max
);

    always @(posedge clk) begin
        if (rst) begin
            value <= 3'd0;
        end
        else begin
            if (clear) value <= 3'd0;
            else if (add && (value < 3'd7)) value <= value + 3'd1;
            else value <= value;
        end
    end

    assign at_max = value == 3'd7;
endmodule
