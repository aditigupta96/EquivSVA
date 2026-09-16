module protocol_controller_0007_onehot_case (
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
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] RUN   = 4'b0010;
    localparam [3:0] PAUSE = 4'b0100;
    localparam [3:0] DONE  = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? RUN : ((!start) ? IDLE : (IDLE));
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
        running = (state == RUN);
        paused = (state == PAUSE);
        done = (state == DONE);
    end
endmodule
