module timer_0008_mutant_age_without_tick (
    input  wire clk,
    input  wire rst,
    input  wire kick,
    input  wire tick,
    output reg  [2:0] age,
    output wire timeout
);

    always @(posedge clk) begin
        if (rst) begin
            age <= 3'd0;
        end
        else begin
            if (kick) age <= 3'd0;
            else if (!kick && (age < 3'd7)) age <= age + 3'd1;
            else age <= age;
        end
    end

    assign timeout = age == 3'd7;
endmodule
