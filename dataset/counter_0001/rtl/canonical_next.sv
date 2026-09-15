module counter_0001_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [1:0] count,
    output wire at_max
);

    reg [1:0] next_count;

    always @* begin
        if (clear) next_count = 2'd0;
        else if (enable && (count < 2'd3)) next_count = count + 2'd1;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign at_max = count == 2'd3;
endmodule
