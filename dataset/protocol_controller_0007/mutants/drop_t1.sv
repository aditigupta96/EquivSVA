module protocol_controller_0007_mutant_drop_t1 (
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
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] PAUSE = 2'd2;
    localparam [1:0] DONE  = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (!start) ? IDLE : (IDLE);
            RUN: next_state = (done_in) ? DONE : ((!done_in && pause) ? PAUSE : ((!done_in && !pause) ? RUN : (RUN)));
            PAUSE: next_state = (resume) ? RUN : ((!resume) ? PAUSE : (PAUSE));
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        running = 1'b0;
        paused = 1'b0;
        done = 1'b0;
        case (state)
            IDLE: begin
                running = 1'b0;
                paused = 1'b0;
                done = 1'b0;
            end
            RUN: begin
                running = 1'b1;
                paused = 1'b0;
                done = 1'b0;
            end
            PAUSE: begin
                running = 1'b0;
                paused = 1'b1;
                done = 1'b0;
            end
            DONE: begin
                running = 1'b0;
                paused = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
