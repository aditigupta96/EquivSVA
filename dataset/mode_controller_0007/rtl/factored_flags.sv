module mode_controller_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire run,
    input  wire fault,
    input  wire clear,
    output reg  standby,
    output reg  running,
    output reg  faulted
);
    localparam [1:0] F_STANDBY      = 2'd0;
    localparam [1:0] F_RUN          = 2'd1;
    localparam [1:0] F_FAULT        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_standby_0 = (run);
    wire guard_standby_1 = (!run);
    wire guard_run_0 = (fault);
    wire guard_run_1 = (!fault && run);
    wire guard_run_2 = (!fault && !run);
    wire guard_fault_0 = (clear);
    wire guard_fault_1 = (!clear);

    always @* begin
        next_state = state;
        case (state)
            F_STANDBY: begin
                if (guard_standby_0)
                    next_state = F_RUN;
                else if (guard_standby_1)
                    next_state = F_STANDBY;
            end
            F_RUN: begin
                if (guard_run_0)
                    next_state = F_FAULT;
                else if (guard_run_1)
                    next_state = F_RUN;
                else if (guard_run_2)
                    next_state = F_STANDBY;
            end
            F_FAULT: begin
                if (guard_fault_0)
                    next_state = F_STANDBY;
                else if (guard_fault_1)
                    next_state = F_FAULT;
            end
            default: next_state = F_STANDBY;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_STANDBY;
        else
            state <= next_state;
    end

    always @* begin
        standby = 1'b0;
        running = 1'b0;
        faulted = 1'b0;
        case (state)
            F_STANDBY: begin
                standby = 1'b1;
                running = 1'b0;
                faulted = 1'b0;
            end
            F_RUN: begin
                standby = 1'b0;
                running = 1'b1;
                faulted = 1'b0;
            end
            F_FAULT: begin
                standby = 1'b0;
                running = 1'b0;
                faulted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
