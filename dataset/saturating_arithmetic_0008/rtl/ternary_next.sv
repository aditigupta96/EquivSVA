module saturating_arithmetic_0008_ternary_next (
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

    assign next_value = (center) ? (4'd6) : ((!center && boost && !drain && (value <= 4'd11)) ? (value + 4'd2) : ((!center && boost && !drain && (value > 4'd11)) ? (4'd13) : ((!center && drain && !boost && (value > 4'd1)) ? (value - 4'd1) : ((!center && drain && !boost && (value == 4'd1)) ? (4'd1) : (value)))));

    always @(posedge clk) begin
        if (rst)
            value <= 4'd6;
        else
            value <= next_value;
    end

    assign high = value >= 4'd10;
    assign low = value <= 4'd3;
endmodule
