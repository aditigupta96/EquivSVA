module fifo_0002_mutant_ignore_pop (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    input  wire [1:0] din,
    output wire [1:0] dout,
    output wire valid,
    output wire ready
);

    reg [1:0] data_reg;
    reg valid_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 2'd0;
            valid_reg <= 1'b0;
        end
        else begin
            if (push && !valid_reg) data_reg <= din;
            else data_reg <= data_reg;
            if (push && !valid_reg) valid_reg <= 1'b1;
            else valid_reg <= valid_reg;
        end
    end

    assign dout = data_reg;
    assign valid = valid_reg;
    assign ready = !valid_reg;
endmodule
