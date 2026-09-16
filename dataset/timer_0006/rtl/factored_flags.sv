module timer_0006_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire kick,
    output reg  armed,
    output reg  warning,
    output reg  timeout
);
    localparam [1:0] F_ARMED        = 2'd0;
    localparam [1:0] F_WARN         = 2'd1;
    localparam [1:0] F_TIMEOUT      = 2'd2;

    reg [1:0] state, next_state;

    wire guard_armed_0 = (kick);
    wire guard_armed_1 = (!kick && tick);
    wire guard_armed_2 = (!kick && !tick);
    wire guard_warn_0 = (kick);
    wire guard_warn_1 = (!kick && tick);
    wire guard_warn_2 = (!kick && !tick);
    wire guard_timeout_0 = (kick);
    wire guard_timeout_1 = (!kick);

    always @* begin
        next_state = state;
        case (state)
            F_ARMED: begin
                if (guard_armed_0)
                    next_state = F_ARMED;
                else if (guard_armed_1)
                    next_state = F_WARN;
                else if (guard_armed_2)
                    next_state = F_ARMED;
            end
            F_WARN: begin
                if (guard_warn_0)
                    next_state = F_ARMED;
                else if (guard_warn_1)
                    next_state = F_TIMEOUT;
                else if (guard_warn_2)
                    next_state = F_WARN;
            end
            F_TIMEOUT: begin
                if (guard_timeout_0)
                    next_state = F_ARMED;
                else if (guard_timeout_1)
                    next_state = F_TIMEOUT;
            end
            default: next_state = F_ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_ARMED;
        else
            state <= next_state;
    end

    always @* begin
        armed = 1'b0;
        warning = 1'b0;
        timeout = 1'b0;
        case (state)
            F_ARMED: begin
                armed = 1'b1;
                warning = 1'b0;
                timeout = 1'b0;
            end
            F_WARN: begin
                armed = 1'b0;
                warning = 1'b1;
                timeout = 1'b0;
            end
            F_TIMEOUT: begin
                armed = 1'b0;
                warning = 1'b0;
                timeout = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
