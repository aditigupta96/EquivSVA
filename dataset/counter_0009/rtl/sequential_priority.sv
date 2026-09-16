module counter_0009_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire up,
    input  wire down,
    output reg  [2:0] count,
    output wire at_zero,
    output wire at_max
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd0;
        end
        else begin
            if (up && !down && (count < 3'd7)) count <= count + 3'd1;
            else if (down && !up && (count > 3'd0)) count <= count - 3'd1;
            else count <= count;
        end
    end

    assign at_zero = count == 3'd0;
    assign at_max = count == 3'd7;
endmodule
