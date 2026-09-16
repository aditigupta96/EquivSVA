module fifo_0006_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    input  wire [2:0] din,
    output wire [2:0] dout,
    output wire valid,
    output wire ready
);

    reg [2:0] data_reg;
    reg valid_reg;

    wire [2:0] next_data_reg;
    wire next_valid_reg;

    assign next_data_reg = (push && (!valid_reg || pop)) ? (din) : (data_reg);
    assign next_valid_reg = (push && (!valid_reg || pop)) ? (1'b1) : ((pop && valid_reg) ? (1'b0) : (valid_reg));

    always @(posedge clk) begin
        if (rst) begin
            data_reg <= 3'd0;
            valid_reg <= 1'b0;
        end
        else begin
            data_reg <= next_data_reg;
            valid_reg <= next_valid_reg;
        end
    end

    assign dout = data_reg;
    assign valid = valid_reg;
    assign ready = !valid_reg || pop;
endmodule
