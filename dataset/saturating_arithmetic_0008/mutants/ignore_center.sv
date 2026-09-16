module saturating_arithmetic_0008_mutant_ignore_center (
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
            if (!center && boost && !drain && (value <= 4'd11)) value <= value + 4'd2;
            else if (!center && boost && !drain && (value > 4'd11)) value <= 4'd13;
            else if (!center && drain && !boost && (value > 4'd1)) value <= value - 4'd1;
            else if (!center && drain && !boost && (value == 4'd1)) value <= 4'd1;
            else value <= value;
        end
    end

    assign high = value >= 4'd10;
    assign low = value <= 4'd3;
endmodule
