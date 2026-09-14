module arbiter_0004_mutant_req0_dominates_after_grant0 (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    output reg  grant0,
    output reg  grant1
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] GRANT0 = 2'd1;
    localparam [1:0] GRANT1 = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (req0) ? GRANT0 : ((req1) ? GRANT1 : (IDLE));
            GRANT0: next_state = (req1 && !req0) ? GRANT1 : ((req0) ? GRANT0 : (IDLE));
            GRANT1: next_state = (req0) ? GRANT0 : ((req1) ? GRANT1 : (IDLE));
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        grant0 = 1'b0;
        grant1 = 1'b0;
        case (state)
            IDLE: begin
                grant0 = 1'b0;
                grant1 = 1'b0;
            end
            GRANT0: begin
                grant0 = 1'b1;
                grant1 = 1'b0;
            end
            GRANT1: begin
                grant0 = 1'b0;
                grant1 = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
