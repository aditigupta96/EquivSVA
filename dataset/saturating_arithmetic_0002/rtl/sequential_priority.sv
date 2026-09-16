module saturating_arithmetic_0002_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire load_mid,
    input  wire inc,
    input  wire dec,
    output reg  [3:0] value,
    output wire at_min,
    output wire at_max
);

    always @(posedge clk) begin
        if (rst) begin
            value <= 4'd8;
        end
        else begin
            if (load_mid) value <= 4'd8;
            else if (!load_mid && inc && !dec && (value < 4'd13)) value <= value + 4'd1;
            else if (!load_mid && dec && !inc && (value > 4'd2)) value <= value - 4'd1;
            else value <= value;
        end
    end

    assign at_min = value == 4'd2;
    assign at_max = value == 4'd13;
endmodule
