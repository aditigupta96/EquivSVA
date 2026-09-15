module counter_0003_mutant_ignore_direction (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    input  wire down,
    output reg  [1:0] count,
    output wire at_min,
    output wire at_max
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 2'd0;
        end
        else begin
            if (clear) count <= 2'd0;
            else if (enable && (count > 2'd0)) count <= count - 2'd1;
            else if (enable && !down && (count < 2'd3)) count <= count + 2'd1;
            else count <= count;
        end
    end

    assign at_min = count == 2'd0;
    assign at_max = count == 2'd3;
endmodule
