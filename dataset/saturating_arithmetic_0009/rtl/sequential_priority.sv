module saturating_arithmetic_0009_sequential_priority (
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

    always @(posedge clk) begin
        if (rst) begin
            value_reg <= 3'd3;
            low_reg <= 1'b0;
            high_reg <= 1'b0;
        end
        else begin
            if (inc && !dec && (value_reg < 3'd6)) value_reg <= value_reg + 3'd1;
            else if (dec && !inc && (value_reg > 3'd1)) value_reg <= value_reg - 3'd1;
            else value_reg <= value_reg;
            if (clear_history) low_reg <= 1'b0;
            else if (dec && !inc && (value_reg == 3'd2)) low_reg <= 1'b1;
            else low_reg <= low_reg;
            if (clear_history) high_reg <= 1'b0;
            else if (inc && !dec && (value_reg == 3'd5)) high_reg <= 1'b1;
            else high_reg <= high_reg;
        end
    end

    assign value = value_reg;
    assign hit_low = low_reg;
    assign hit_high = high_reg;
endmodule
