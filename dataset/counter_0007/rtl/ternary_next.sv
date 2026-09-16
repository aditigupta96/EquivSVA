module counter_0007_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire reload,
    input  wire enable,
    output reg  [2:0] count,
    output wire at_zero
);

    wire [2:0] next_count;

    assign next_count = (reload) ? (3'd7) : ((!reload && enable && (count > 3'd0)) ? (count - 3'd1) : (count));

    always @(posedge clk) begin
        if (rst)
            count <= 3'd7;
        else
            count <= next_count;
    end

    assign at_zero = count == 3'd0;
endmodule
