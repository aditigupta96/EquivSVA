module protocol_controller_0010_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire quiesce,
    input  wire idle_seen,
    output reg  running,
    output reg  draining,
    output reg  stopped
);
    localparam [1:0] F_STOP         = 2'd0;
    localparam [1:0] F_RUN          = 2'd1;
    localparam [1:0] F_DRAIN        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_stop_0 = (enable);
    wire guard_stop_1 = (!enable);
    wire guard_run_0 = (quiesce);
    wire guard_run_1 = (!quiesce);
    wire guard_drain_0 = (idle_seen);
    wire guard_drain_1 = (!idle_seen);

    always @* begin
        next_state = state;
        case (state)
            F_STOP: begin
                if (guard_stop_0)
                    next_state = F_RUN;
                else if (guard_stop_1)
                    next_state = F_STOP;
            end
            F_RUN: begin
                if (guard_run_0)
                    next_state = F_DRAIN;
                else if (guard_run_1)
                    next_state = F_RUN;
            end
            F_DRAIN: begin
                if (guard_drain_0)
                    next_state = F_STOP;
                else if (guard_drain_1)
                    next_state = F_DRAIN;
            end
            default: next_state = F_STOP;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_STOP;
        else
            state <= next_state;
    end

    always @* begin
        running = 1'b0;
        draining = 1'b0;
        stopped = 1'b0;
        case (state)
            F_STOP: begin
                running = 1'b0;
                draining = 1'b0;
                stopped = 1'b1;
            end
            F_RUN: begin
                running = 1'b1;
                draining = 1'b0;
                stopped = 1'b0;
            end
            F_DRAIN: begin
                running = 1'b0;
                draining = 1'b1;
                stopped = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
