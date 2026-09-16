module mode_controller_0010_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire auto_mode,
    input  wire turn_off,
    output reg  manual,
    output reg  auto_active,
    output reg  off
);
    localparam [1:0] F_OFF          = 2'd0;
    localparam [1:0] F_MANUAL       = 2'd1;
    localparam [1:0] F_AUTO         = 2'd2;

    reg [1:0] state, next_state;

    wire guard_off_0 = (enable && auto_mode);
    wire guard_off_1 = (enable && !auto_mode);
    wire guard_off_2 = (!enable);
    wire guard_manual_0 = (turn_off);
    wire guard_manual_1 = (!turn_off && auto_mode);
    wire guard_manual_2 = (!turn_off && !auto_mode);
    wire guard_auto_0 = (turn_off);
    wire guard_auto_1 = (!turn_off && !auto_mode);
    wire guard_auto_2 = (!turn_off && auto_mode);

    always @* begin
        next_state = state;
        case (state)
            F_OFF: begin
                if (guard_off_0)
                    next_state = F_AUTO;
                else if (guard_off_1)
                    next_state = F_MANUAL;
                else if (guard_off_2)
                    next_state = F_OFF;
            end
            F_MANUAL: begin
                if (guard_manual_0)
                    next_state = F_OFF;
                else if (guard_manual_1)
                    next_state = F_AUTO;
                else if (guard_manual_2)
                    next_state = F_MANUAL;
            end
            F_AUTO: begin
                if (guard_auto_0)
                    next_state = F_OFF;
                else if (guard_auto_1)
                    next_state = F_MANUAL;
                else if (guard_auto_2)
                    next_state = F_AUTO;
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
        manual = 1'b0;
        auto_active = 1'b0;
        off = 1'b0;
        case (state)
            F_OFF: begin
                manual = 1'b0;
                off = 1'b1;
                auto_active = 1'b0;
            end
            F_MANUAL: begin
                manual = 1'b1;
                off = 1'b0;
                auto_active = 1'b0;
            end
            F_AUTO: begin
                manual = 1'b0;
                off = 1'b0;
                auto_active = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
