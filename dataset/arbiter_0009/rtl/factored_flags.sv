module arbiter_0009_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire lock,
    output reg  grant0,
    output reg  grant1
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_G0           = 2'd1;
    localparam [1:0] F_G1           = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (req1);
    wire guard_idle_1 = (!req1 && req0);
    wire guard_idle_2 = (!req1 && !req0);
    wire guard_g0_0 = (lock);
    wire guard_g0_1 = (!lock);
    wire guard_g1_0 = (lock);
    wire guard_g1_1 = (!lock);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_G1;
                else if (guard_idle_1)
                    next_state = F_G0;
                else if (guard_idle_2)
                    next_state = F_IDLE;
            end
            F_G0: begin
                if (guard_g0_0)
                    next_state = F_G0;
                else if (guard_g0_1)
                    next_state = F_IDLE;
            end
            F_G1: begin
                if (guard_g1_0)
                    next_state = F_G1;
                else if (guard_g1_1)
                    next_state = F_IDLE;
            end
            default: next_state = F_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        grant0 = 1'b0;
        grant1 = 1'b0;
        case (state)
            F_IDLE: begin
                grant0 = 1'b0;
                grant1 = 1'b0;
            end
            F_G0: begin
                grant0 = 1'b1;
                grant1 = 1'b0;
            end
            F_G1: begin
                grant0 = 1'b0;
                grant1 = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
