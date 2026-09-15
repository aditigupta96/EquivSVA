module counter_0005_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire load,
    input  wire tick,
    input  wire [1:0] load_value,
    output reg  [1:0] count,
    output wire expired
);

    wire [1:0] next_count;

    assign next_count = (clear) ? (2'd0) : ((load) ? (load_value) : ((tick && (count > 2'd0)) ? (count - 2'd1) : (count)));

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign expired = count == 2'd0;
endmodule
