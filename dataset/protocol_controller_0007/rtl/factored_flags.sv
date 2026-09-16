module protocol_controller_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire pause,
    input  wire resume,
    input  wire done_in,
    output reg  running,
    output reg  paused,
    output reg  done
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_RUN          = 2'd1;
    localparam [1:0] F_PAUSE        = 2'd2;
    localparam [1:0] F_DONE         = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_idle_1 = (!start);
    wire guard_run_0 = (done_in);
    wire guard_run_1 = (!done_in && pause);
    wire guard_run_2 = (!done_in && !pause);
    wire guard_pause_0 = (resume);
    wire guard_pause_1 = (!resume);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_RUN;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_RUN: begin
                if (guard_run_0)
                    next_state = F_DONE;
                else if (guard_run_1)
                    next_state = F_PAUSE;
                else if (guard_run_2)
                    next_state = F_RUN;
            end
            F_PAUSE: begin
                if (guard_pause_0)
                    next_state = F_RUN;
                else if (guard_pause_1)
                    next_state = F_PAUSE;
            end
            F_DONE: begin
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
        paused = 1'b0;
        done = 1'b0;
        case (state)
            F_IDLE: begin
                running = 1'b0;
                paused = 1'b0;
                done = 1'b0;
            end
            F_RUN: begin
                running = 1'b1;
                paused = 1'b0;
                done = 1'b0;
            end
            F_PAUSE: begin
                running = 1'b0;
                paused = 1'b1;
                done = 1'b0;
            end
            F_DONE: begin
                running = 1'b0;
                paused = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
