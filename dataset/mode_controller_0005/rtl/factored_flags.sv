module mode_controller_0005_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire activate,
    input  wire boost,
    input  wire idle,
    output reg  active,
    output reg  boosted,
    output reg  idle_mode
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_ACTIVE       = 2'd1;
    localparam [1:0] F_BOOST        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (activate);
    wire guard_idle_1 = (!activate);
    wire guard_active_0 = (boost);
    wire guard_active_1 = (!boost && idle);
    wire guard_active_2 = (!boost && !idle);
    wire guard_boost_0 = (boost);
    wire guard_boost_1 = (!boost);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_ACTIVE;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_ACTIVE: begin
                if (guard_active_0)
                    next_state = F_BOOST;
                else if (guard_active_1)
                    next_state = F_IDLE;
                else if (guard_active_2)
                    next_state = F_ACTIVE;
            end
            F_BOOST: begin
                if (guard_boost_0)
                    next_state = F_BOOST;
                else if (guard_boost_1)
                    next_state = F_ACTIVE;
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
        active = 1'b0;
        boosted = 1'b0;
        idle_mode = 1'b0;
        case (state)
            F_IDLE: begin
                active = 1'b0;
                boosted = 1'b0;
                idle_mode = 1'b1;
            end
            F_ACTIVE: begin
                active = 1'b1;
                boosted = 1'b0;
                idle_mode = 1'b0;
            end
            F_BOOST: begin
                active = 1'b0;
                boosted = 1'b1;
                idle_mode = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
