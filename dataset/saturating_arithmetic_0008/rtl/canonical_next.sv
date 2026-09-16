module saturating_arithmetic_0008_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire center,
    input  wire boost,
    input  wire drain,
    output reg  [3:0] value,
    output wire high,
    output wire low
);

    reg [3:0] next_value;

    always @* begin
        if (center) next_value = 4'd6;
        else if (!center && boost && !drain && (value <= 4'd11)) next_value = value + 4'd2;
        else if (!center && boost && !drain && (value > 4'd11)) next_value = 4'd13;
        else if (!center && drain && !boost && (value > 4'd1)) next_value = value - 4'd1;
        else if (!center && drain && !boost && (value == 4'd1)) next_value = 4'd1;
        else next_value = value;
    end

    always @(posedge clk) begin
        if (rst)
            value <= 4'd6;
        else
            value <= next_value;
    end

    assign high = value >= 4'd10;
    assign low = value <= 4'd3;
endmodule
