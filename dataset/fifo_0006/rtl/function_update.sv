module fifo_0006_function_update (
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

    function automatic [2:0] compute_next_data_reg;
        input [2:0] current_data_reg;
        input current_valid_reg;
        input push;
        input pop;
        input [2:0] din;
        begin
            if (push && (!current_valid_reg || pop)) compute_next_data_reg = din;
            else compute_next_data_reg = current_data_reg;
        end
    endfunction

    function automatic compute_next_valid_reg;
        input [2:0] current_data_reg;
        input current_valid_reg;
        input push;
        input pop;
        input [2:0] din;
        begin
            if (push && (!current_valid_reg || pop)) compute_next_valid_reg = 1'b1;
            else if (pop && current_valid_reg) compute_next_valid_reg = 1'b0;
            else compute_next_valid_reg = current_valid_reg;
        end
    endfunction

    wire [2:0] next_data_reg;
    wire next_valid_reg;

    assign next_data_reg = compute_next_data_reg(data_reg, valid_reg, push, pop, din);
    assign next_valid_reg = compute_next_valid_reg(data_reg, valid_reg, push, pop, din);

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
