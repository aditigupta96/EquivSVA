module timer_0009_mutant_ignore_clear (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [2:0] count,
    output wire done
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd0;
        end
        else begin
            if (!clear && enable && (count < 3'd5)) count <= count + 3'd1;
            else count <= count;
        end
    end

    assign done = count == 3'd5;
endmodule
