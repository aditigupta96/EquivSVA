module counter_0004_mutant_increment_when_disabled (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire load,
    input  wire enable,
    input  wire [1:0] load_value,
    output reg  [1:0] count,
    output wire at_max
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 2'd0;
        end
        else begin
            if (clear) count <= 2'd0;
            else if (load) count <= load_value;
            else if (count < 2'd3) count <= count + 2'd1;
            else count <= count;
        end
    end

    assign at_max = count == 2'd3;
endmodule
