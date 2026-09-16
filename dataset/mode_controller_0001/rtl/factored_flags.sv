module mode_controller_0001_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire wake,
    input  wire fault,
    input  wire clear_fault,
    output reg  standby,
    output reg  active,
    output reg  faulted
);
    localparam [1:0] F_OFF          = 2'd0;
    localparam [1:0] F_STANDBY      = 2'd1;
    localparam [1:0] F_ACTIVE       = 2'd2;
    localparam [1:0] F_FAULT        = 2'd3;

    reg [1:0] state, next_state;

    wire guard_off_0 = (enable);
    wire guard_off_1 = (!enable);
    wire guard_standby_0 = (fault);
    wire guard_standby_1 = (!fault && !enable);
    wire guard_standby_2 = (!fault && enable && wake);
    wire guard_standby_3 = (!fault && enable && !wake);
    wire guard_active_0 = (fault);
    wire guard_active_1 = (!fault && !enable);
    wire guard_active_2 = (!fault && enable && !wake);
    wire guard_active_3 = (!fault && enable && wake);
    wire guard_fault_0 = (clear_fault);
    wire guard_fault_1 = (!clear_fault);

    always @* begin
        next_state = state;
        case (state)
            F_OFF: begin
                if (guard_off_0)
                    next_state = F_STANDBY;
                else if (guard_off_1)
                    next_state = F_OFF;
            end
            F_STANDBY: begin
                if (guard_standby_0)
                    next_state = F_FAULT;
                else if (guard_standby_1)
                    next_state = F_OFF;
                else if (guard_standby_2)
                    next_state = F_ACTIVE;
                else if (guard_standby_3)
                    next_state = F_STANDBY;
            end
            F_ACTIVE: begin
                if (guard_active_0)
                    next_state = F_FAULT;
                else if (guard_active_1)
                    next_state = F_OFF;
                else if (guard_active_2)
                    next_state = F_STANDBY;
                else if (guard_active_3)
                    next_state = F_ACTIVE;
            end
            F_FAULT: begin
                if (guard_fault_0)
                    next_state = F_OFF;
                else if (guard_fault_1)
                    next_state = F_FAULT;
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
        standby = 1'b0;
        active = 1'b0;
        faulted = 1'b0;
        case (state)
            F_OFF: begin
                standby = 1'b0;
                active = 1'b0;
                faulted = 1'b0;
            end
            F_STANDBY: begin
                standby = 1'b1;
                active = 1'b0;
                faulted = 1'b0;
            end
            F_ACTIVE: begin
                standby = 1'b0;
                active = 1'b1;
                faulted = 1'b0;
            end
            F_FAULT: begin
                standby = 1'b0;
                active = 1'b0;
                faulted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
