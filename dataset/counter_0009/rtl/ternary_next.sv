module counter_0009_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire up,
    input  wire down,
    output reg  [2:0] count,
    output wire at_zero,
    output wire at_max
);

    wire [2:0] next_count;

    assign next_count = (up && !down && (count < 3'd7)) ? (count + 3'd1) : ((down && !up && (count > 3'd0)) ? (count - 3'd1) : (count));

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign at_zero = count == 3'd0;
    assign at_max = count == 3'd7;
endmodule
