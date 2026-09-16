module rate_limiter_0010_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire violation,
    input  wire clear,
    output reg  clean,
    output reg  strike1,
    output reg  strike2,
    output reg  blocked
);
    localparam [1:0] F_CLEAN        = 2'd0;
    localparam [1:0] F_S1           = 2'd1;
    localparam [1:0] F_S2           = 2'd2;
    localparam [1:0] F_BLOCKED      = 2'd3;

    reg [1:0] state, next_state;

    wire guard_clean_0 = (violation);
    wire guard_clean_1 = (!violation);
    wire guard_s1_0 = (violation);
    wire guard_s1_1 = (!violation);
    wire guard_s2_0 = (violation);
    wire guard_s2_1 = (!violation);
    wire guard_blocked_0 = (clear);
    wire guard_blocked_1 = (!clear);

    always @* begin
        next_state = state;
        case (state)
            F_CLEAN: begin
                if (guard_clean_0)
                    next_state = F_S1;
                else if (guard_clean_1)
                    next_state = F_CLEAN;
            end
            F_S1: begin
                if (guard_s1_0)
                    next_state = F_S2;
                else if (guard_s1_1)
                    next_state = F_CLEAN;
            end
            F_S2: begin
                if (guard_s2_0)
                    next_state = F_BLOCKED;
                else if (guard_s2_1)
                    next_state = F_CLEAN;
            end
            F_BLOCKED: begin
                if (guard_blocked_0)
                    next_state = F_CLEAN;
                else if (guard_blocked_1)
                    next_state = F_BLOCKED;
            end
            default: next_state = F_CLEAN;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_CLEAN;
        else
            state <= next_state;
    end

    always @* begin
        clean = 1'b0;
        strike1 = 1'b0;
        strike2 = 1'b0;
        blocked = 1'b0;
        case (state)
            F_CLEAN: begin
                clean = 1'b1;
                strike1 = 1'b0;
                strike2 = 1'b0;
                blocked = 1'b0;
            end
            F_S1: begin
                clean = 1'b0;
                strike1 = 1'b1;
                strike2 = 1'b0;
                blocked = 1'b0;
            end
            F_S2: begin
                clean = 1'b0;
                strike1 = 1'b0;
                strike2 = 1'b1;
                blocked = 1'b0;
            end
            F_BLOCKED: begin
                clean = 1'b0;
                strike1 = 1'b0;
                strike2 = 1'b0;
                blocked = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
