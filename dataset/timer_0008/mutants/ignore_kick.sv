module timer_0008_mutant_ignore_kick (
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
            if (!kick && tick && (age < 3'd7)) age <= age + 3'd1;
            else age <= age;
        end
    end

    assign timeout = age == 3'd7;
endmodule
