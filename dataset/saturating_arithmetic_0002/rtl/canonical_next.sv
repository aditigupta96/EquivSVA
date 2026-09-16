module saturating_arithmetic_0002_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire load_mid,
    input  wire inc,
    input  wire dec,
    output reg  [3:0] value,
    output wire at_min,
    output wire at_max
);

    reg [3:0] next_value;

    always @* begin
        if (load_mid) next_value = 4'd8;
        else if (!load_mid && inc && !dec && (value < 4'd13)) next_value = value + 4'd1;
        else if (!load_mid && dec && !inc && (value > 4'd2)) next_value = value - 4'd1;
        else next_value = value;
    end

    always @(posedge clk) begin
        if (rst)
            value <= 4'd8;
        else
            value <= next_value;
    end

    assign at_min = value == 4'd2;
    assign at_max = value == 4'd13;
endmodule
