module counter_0002_mutant_saturate_at_max (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [1:0] count,
    output wire is_zero
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 2'd0;
        end
        else begin
            if (clear) count <= 2'd0;
            else if (enable && (count == 2'd3)) count <= count;
            else if (enable && (count < 2'd3)) count <= count + 2'd1;
            else count <= count;
        end
    end

    assign is_zero = count == 2'd0;
endmodule
