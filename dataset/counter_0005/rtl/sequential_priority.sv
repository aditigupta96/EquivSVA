module counter_0005_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire load,
    input  wire tick,
    input  wire [1:0] load_value,
    output reg  [1:0] count,
    output wire expired
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 2'd0;
        end
        else begin
            if (clear) count <= 2'd0;
            else if (load) count <= load_value;
            else if (tick && (count > 2'd0)) count <= count - 2'd1;
            else count <= count;
        end
    end

    assign expired = count == 2'd0;
endmodule
