module saturating_arithmetic_0009_canonical_next (
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

    reg [2:0] next_value_reg;
    reg next_low_reg;
    reg next_high_reg;

    always @* begin
        if (inc && !dec && (value_reg < 3'd6)) next_value_reg = value_reg + 3'd1;
        else if (dec && !inc && (value_reg > 3'd1)) next_value_reg = value_reg - 3'd1;
        else next_value_reg = value_reg;
        if (clear_history) next_low_reg = 1'b0;
        else if (dec && !inc && (value_reg == 3'd2)) next_low_reg = 1'b1;
        else next_low_reg = low_reg;
        if (clear_history) next_high_reg = 1'b0;
        else if (inc && !dec && (value_reg == 3'd5)) next_high_reg = 1'b1;
        else next_high_reg = high_reg;
    end

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
