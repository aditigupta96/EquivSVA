module mode_controller_0002_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire sleep,
    input  wire wake,
    output reg  active,
    output reg  sleeping,
    output reg  off
);
    localparam [1:0] F_OFF          = 2'd0;
    localparam [1:0] F_ACTIVE       = 2'd1;
    localparam [1:0] F_SLEEP        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_off_0 = (enable);
    wire guard_off_1 = (!enable);
    wire guard_active_0 = (!enable);
    wire guard_active_1 = (enable && sleep);
    wire guard_active_2 = (enable && !sleep);
    wire guard_sleep_0 = (!enable);
    wire guard_sleep_1 = (enable && wake);
    wire guard_sleep_2 = (enable && !wake);

    always @* begin
        next_state = state;
        case (state)
            F_OFF: begin
                if (guard_off_0)
                    next_state = F_ACTIVE;
                else if (guard_off_1)
                    next_state = F_OFF;
            end
            F_ACTIVE: begin
                if (guard_active_0)
                    next_state = F_OFF;
                else if (guard_active_1)
                    next_state = F_SLEEP;
                else if (guard_active_2)
                    next_state = F_ACTIVE;
            end
            F_SLEEP: begin
                if (guard_sleep_0)
                    next_state = F_OFF;
                else if (guard_sleep_1)
                    next_state = F_ACTIVE;
                else if (guard_sleep_2)
                    next_state = F_SLEEP;
            end
            default: next_state = F_OFF;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_OFF;
        else
            state <= next_state;
    end

    always @* begin
        active = 1'b0;
        sleeping = 1'b0;
        off = 1'b0;
        case (state)
            F_OFF: begin
                active = 1'b0;
                sleeping = 1'b0;
                off = 1'b1;
            end
            F_ACTIVE: begin
                active = 1'b1;
                sleeping = 1'b0;
                off = 1'b0;
            end
            F_SLEEP: begin
                active = 1'b0;
                sleeping = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
