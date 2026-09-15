module counter_0005_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire load,
    input  wire tick,
    input  wire [1:0] load_value,
    output reg  [1:0] count,
    output wire expired
);

    reg [1:0] next_count;

    always @* begin
        if (clear) next_count = 2'd0;
        else if (load) next_count = load_value;
        else if (tick && (count > 2'd0)) next_count = count - 2'd1;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign expired = count == 2'd0;
endmodule
