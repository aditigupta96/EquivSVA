module counter_0008_mutant_never_step (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire step,
    output reg  [2:0] count,
    output wire at_limit
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd0;
        end
        else begin
            if (clear) count <= 3'd0;
            else count <= count;
        end
    end

    assign at_limit = count == 3'd6;
endmodule
