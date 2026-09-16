module counter_0007_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire reload,
    input  wire enable,
    output reg  [2:0] count,
    output wire at_zero
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd7;
        end
        else begin
            if (reload) count <= 3'd7;
            else if (!reload && enable && (count > 3'd0)) count <= count - 3'd1;
            else count <= count;
        end
    end

    assign at_zero = count == 3'd0;
endmodule
