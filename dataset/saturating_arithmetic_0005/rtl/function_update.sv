module saturating_arithmetic_0005_function_update (
    input  wire clk,
    input  wire rst,
    input  wire center,
    input  wire boost,
    input  wire drain,
    output reg  [3:0] value,
    output wire high,
    output wire low
);

    function automatic [3:0] compute_next_value;
        input [3:0] current;
        input center;
        input boost;
        input drain;
        begin
            if (center) compute_next_value = 4'd6;
            else if (!center && boost && (current <= 4'd9)) compute_next_value = current + 4'd3;
            else if (!center && boost && (current > 4'd9)) compute_next_value = 4'd12;
            else if (!center && !boost && drain && (current >= 4'd4)) compute_next_value = current - 4'd2;
            else if (!center && !boost && drain && (current < 4'd4)) compute_next_value = 4'd2;
            else compute_next_value = current;
        end
    endfunction

    wire [3:0] next_value;

    assign next_value = compute_next_value(value, center, boost, drain);

    always @(posedge clk) begin
        if (rst)
            value <= 4'd6;
        else
            value <= next_value;
    end

    assign high = value >= 4'd9;
    assign low = value <= 4'd3;
endmodule
