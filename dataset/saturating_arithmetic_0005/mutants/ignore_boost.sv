module saturating_arithmetic_0005_mutant_ignore_boost (
    input  wire clk,
    input  wire rst,
    input  wire center,
    input  wire boost,
    input  wire drain,
    output reg  [3:0] value,
    output wire high,
    output wire low
);

    always @(posedge clk) begin
        if (rst) begin
            value <= 4'd6;
        end
        else begin
            if (center) value <= 4'd6;
            else if (!center && boost && (value > 4'd9)) value <= 4'd12;
            else if (!center && !boost && drain && (value >= 4'd4)) value <= value - 4'd2;
            else if (!center && !boost && drain && (value < 4'd4)) value <= 4'd2;
            else value <= value;
        end
    end

    assign high = value >= 4'd9;
    assign low = value <= 4'd3;
endmodule
