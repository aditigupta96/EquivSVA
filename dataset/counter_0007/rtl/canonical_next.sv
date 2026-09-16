module counter_0007_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire reload,
    input  wire enable,
    output reg  [2:0] count,
    output wire at_zero
);

    reg [2:0] next_count;

    always @* begin
        if (reload) next_count = 3'd7;
        else if (!reload && enable && (count > 3'd0)) next_count = count - 3'd1;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 3'd7;
        else
            count <= next_count;
    end

    assign at_zero = count == 3'd0;
endmodule
