module saturating_arithmetic_0001_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire add,
    output reg  [2:0] value,
    output wire at_max
);

    wire [2:0] next_value;

    assign next_value = (clear) ? (3'd0) : ((add && (value < 3'd7)) ? (value + 3'd1) : (value));

    always @(posedge clk) begin
        if (rst)
            value <= 3'd0;
        else
            value <= next_value;
    end

    assign at_max = value == 3'd7;
endmodule
