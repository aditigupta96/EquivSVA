module counter_0010_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire increment,
    output reg  [2:0] count,
    output wire nonzero
);

    reg [2:0] next_count;

    always @* begin
        if (load) next_count = 3'd4;
        else if (!load && increment && (count < 3'd7)) next_count = count + 3'd1;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign nonzero = count != 3'd0;
endmodule
