module saturating_arithmetic_0002_function_update (
    input  wire clk,
    input  wire rst,
    input  wire load_mid,
    input  wire inc,
    input  wire dec,
    output reg  [3:0] value,
    output wire at_min,
    output wire at_max
);

    function automatic [3:0] compute_next_value;
        input [3:0] current;
        input load_mid;
        input inc;
        input dec;
        begin
            if (load_mid) compute_next_value = 4'd8;
            else if (!load_mid && inc && !dec && (current < 4'd13)) compute_next_value = current + 4'd1;
            else if (!load_mid && dec && !inc && (current > 4'd2)) compute_next_value = current - 4'd1;
            else compute_next_value = current;
        end
    endfunction

    wire [3:0] next_value;

    assign next_value = compute_next_value(value, load_mid, inc, dec);

    always @(posedge clk) begin
        if (rst)
            value <= 4'd8;
        else
            value <= next_value;
    end

    assign at_min = value == 4'd2;
    assign at_max = value == 4'd13;
endmodule
