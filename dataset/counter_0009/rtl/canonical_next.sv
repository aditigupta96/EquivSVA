module counter_0009_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire up,
    input  wire down,
    output reg  [2:0] count,
    output wire at_zero,
    output wire at_max
);

    reg [2:0] next_count;

    always @* begin
        if (up && !down && (count < 3'd7)) next_count = count + 3'd1;
        else if (down && !up && (count > 3'd0)) next_count = count - 3'd1;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign at_zero = count == 3'd0;
    assign at_max = count == 3'd7;
endmodule
