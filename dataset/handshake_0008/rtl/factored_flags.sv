module handshake_0008_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire accept,
    input  wire retry,
    output reg  busy,
    output reg  retrying,
    output reg  done
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_WAIT         = 2'd1;
    localparam [1:0] F_RETRY        = 2'd2;
    localparam [1:0] F_DONE         = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (req);
    wire guard_idle_1 = (!req);
    wire guard_wait_0 = (retry);
    wire guard_wait_1 = (!retry && accept);
    wire guard_wait_2 = (!retry && !accept);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_WAIT;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_WAIT: begin
                if (guard_wait_0)
                    next_state = F_RETRY;
                else if (guard_wait_1)
                    next_state = F_DONE;
                else if (guard_wait_2)
                    next_state = F_WAIT;
            end
            F_RETRY: begin
                next_state = F_WAIT;
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
        busy = 1'b0;
        retrying = 1'b0;
        done = 1'b0;
        case (state)
            F_IDLE: begin
                busy = 1'b0;
                retrying = 1'b0;
                done = 1'b0;
            end
            F_WAIT: begin
                busy = 1'b1;
                retrying = 1'b0;
                done = 1'b0;
            end
            F_RETRY: begin
                busy = 1'b0;
                retrying = 1'b1;
                done = 1'b0;
            end
            F_DONE: begin
                busy = 1'b0;
                retrying = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
