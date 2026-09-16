module counter_0008_mutant_ignore_clear (
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
            if (!clear && step && (count < 3'd6)) count <= count + 3'd2;
            else count <= count;
        end
    end

    assign at_limit = count == 3'd6;
endmodule
