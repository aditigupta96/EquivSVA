module saturating_arithmetic_0009_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear_history,
    input  wire inc,
    input  wire dec,
    output wire [2:0] value,
    output wire hit_low,
    output wire hit_high
);

    reg [2:0] value_reg;
    reg low_reg;
    reg high_reg;

    wire [2:0] next_value_reg;
    wire next_low_reg;
    wire next_high_reg;

    assign next_value_reg = (inc && !dec && (value_reg < 3'd6)) ? (value_reg + 3'd1) : ((dec && !inc && (value_reg > 3'd1)) ? (value_reg - 3'd1) : (value_reg));
    assign next_low_reg = (clear_history) ? (1'b0) : ((dec && !inc && (value_reg == 3'd2)) ? (1'b1) : (low_reg));
    assign next_high_reg = (clear_history) ? (1'b0) : ((inc && !dec && (value_reg == 3'd5)) ? (1'b1) : (high_reg));

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 3'd3;
            low_reg <= 1'b0;
            high_reg <= 1'b0;
        end
        else begin
            value_reg <= next_value_reg;
            low_reg <= next_low_reg;
            high_reg <= next_high_reg;
        end
    end

    assign value = value_reg;
    assign hit_low = low_reg;
    assign hit_high = high_reg;
endmodule
