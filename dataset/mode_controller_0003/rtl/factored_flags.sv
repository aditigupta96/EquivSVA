module mode_controller_0003_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire maintenance,
    input  wire exit_maintenance,
    output reg  normal,
    output reg  maint,
    output reg  off
);
    localparam [1:0] F_OFF          = 2'd0;
    localparam [1:0] F_NORMAL       = 2'd1;
    localparam [1:0] F_MAINT        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_off_0 = (enable);
    wire guard_off_1 = (!enable);
    wire guard_normal_0 = (maintenance);
    wire guard_normal_1 = (!maintenance && !enable);
    wire guard_normal_2 = (!maintenance && enable);
    wire guard_maint_0 = (exit_maintenance);
    wire guard_maint_1 = (!exit_maintenance);

    always @* begin
        next_state = state;
        case (state)
            F_OFF: begin
                if (guard_off_0)
                    next_state = F_NORMAL;
                else if (guard_off_1)
                    next_state = F_OFF;
            end
            F_NORMAL: begin
                if (guard_normal_0)
                    next_state = F_MAINT;
                else if (guard_normal_1)
                    next_state = F_OFF;
                else if (guard_normal_2)
                    next_state = F_NORMAL;
            end
            F_MAINT: begin
                if (guard_maint_0)
                    next_state = F_NORMAL;
                else if (guard_maint_1)
                    next_state = F_MAINT;
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
        normal = 1'b0;
        maint = 1'b0;
        off = 1'b0;
        case (state)
            F_OFF: begin
                normal = 1'b0;
                maint = 1'b0;
                off = 1'b1;
            end
            F_NORMAL: begin
                normal = 1'b1;
                maint = 1'b0;
                off = 1'b0;
            end
            F_MAINT: begin
                normal = 1'b0;
                maint = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
