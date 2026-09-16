module counter_0010_mutant_ignore_load (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire increment,
    output reg  [2:0] count,
    output wire nonzero
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 3'd0;
        end
        else begin
            if (!load && increment && (count < 3'd7)) count <= count + 3'd1;
            else count <= count;
        end
    end

    assign nonzero = count != 3'd0;
endmodule
