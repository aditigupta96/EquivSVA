module timer_0008_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire kick,
    input  wire tick,
    output reg  [2:0] age,
    output wire timeout
);

    wire [2:0] next_age;

    assign next_age = (kick) ? (3'd0) : ((!kick && tick && (age < 3'd7)) ? (age + 3'd1) : (age));

    always @(posedge clk) begin
        if (rst)
            age <= 3'd0;
        else
            age <= next_age;
    end

    assign timeout = age == 3'd7;
endmodule
