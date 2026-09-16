module saturating_arithmetic_0002_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire load_mid,
    input  wire inc,
    input  wire dec,
    output reg  [3:0] value,
    output wire at_min,
    output wire at_max
);

    wire [3:0] next_value;

    assign next_value = (load_mid) ? (4'd8) : ((!load_mid && inc && !dec && (value < 4'd13)) ? (value + 4'd1) : ((!load_mid && dec && !inc && (value > 4'd2)) ? (value - 4'd1) : (value)));

    always @(posedge clk) begin
        if (rst)
            value <= 4'd8;
        else
            value <= next_value;
    end

    assign at_min = value == 4'd2;
    assign at_max = value == 4'd13;
endmodule
