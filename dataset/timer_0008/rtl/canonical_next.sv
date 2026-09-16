module timer_0008_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire kick,
    input  wire tick,
    output reg  [2:0] age,
    output wire timeout
);

    reg [2:0] next_age;

    always @* begin
        if (kick) next_age = 3'd0;
        else if (!kick && tick && (age < 3'd7)) next_age = age + 3'd1;
        else next_age = age;
    end

    always @(posedge clk) begin
        if (rst)
            age <= 3'd0;
        else
            age <= next_age;
    end

    assign timeout = age == 3'd7;
endmodule
