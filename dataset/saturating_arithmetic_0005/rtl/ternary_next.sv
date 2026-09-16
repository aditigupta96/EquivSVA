module saturating_arithmetic_0005_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire center,
    input  wire boost,
    input  wire drain,
    output reg  [3:0] value,
    output wire high,
    output wire low
);

    wire [3:0] next_value;

    assign next_value = (center) ? (4'd6) : ((!center && boost && (value <= 4'd9)) ? (value + 4'd3) : ((!center && boost && (value > 4'd9)) ? (4'd12) : ((!center && !boost && drain && (value >= 4'd4)) ? (value - 4'd2) : ((!center && !boost && drain && (value < 4'd4)) ? (4'd2) : (value)))));

    always @(posedge clk) begin
        if (rst)
            value <= 4'd6;
        else
            value <= next_value;
    end

    assign high = value >= 4'd9;
    assign low = value <= 4'd3;
endmodule
