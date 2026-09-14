module timer_0001_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire kick,
    output reg  running,
    output reg  warning,
    output reg  timeout
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_RUN          = 2'd1;
    localparam [1:0] F_WARNING      = 2'd2;
    localparam [1:0] F_TIMEOUT      = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_run_0 = (kick);
    wire guard_warning_0 = (kick);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_RUN;
                else
                    next_state = F_IDLE;
            end
            F_RUN: begin
                if (guard_run_0)
                    next_state = F_RUN;
                else
                    next_state = F_WARNING;
            end
            F_WARNING: begin
                if (guard_warning_0)
                    next_state = F_RUN;
                else
                    next_state = F_TIMEOUT;
            end
            F_TIMEOUT: begin
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
        running = 1'b0;
        warning = 1'b0;
        timeout = 1'b0;
        case (state)
            F_IDLE: begin
                running = 1'b0;
                warning = 1'b0;
                timeout = 1'b0;
            end
            F_RUN: begin
                running = 1'b1;
                warning = 1'b0;
                timeout = 1'b0;
            end
            F_WARNING: begin
                running = 1'b1;
                warning = 1'b1;
                timeout = 1'b0;
            end
            F_TIMEOUT: begin
                running = 1'b0;
                warning = 1'b0;
                timeout = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
