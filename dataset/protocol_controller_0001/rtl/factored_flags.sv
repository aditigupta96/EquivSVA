module protocol_controller_0001_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ack,
    input  wire abort,
    output reg  busy,
    output reg  done,
    output reg  error
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_WAIT_ACK     = 2'd1;
    localparam [1:0] F_DONE         = 2'd2;
    localparam [1:0] F_ERROR        = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_idle_1 = (!start);
    wire guard_wait_ack_0 = (abort);
    wire guard_wait_ack_1 = (!abort && ack);
    wire guard_wait_ack_2 = (!abort && !ack);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_WAIT_ACK;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_WAIT_ACK: begin
                if (guard_wait_ack_0)
                    next_state = F_ERROR;
                else if (guard_wait_ack_1)
                    next_state = F_DONE;
                else if (guard_wait_ack_2)
                    next_state = F_WAIT_ACK;
            end
            F_DONE: begin
                next_state = F_IDLE;
            end
            F_ERROR: begin
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
        done = 1'b0;
        error = 1'b0;
        case (state)
            F_IDLE: begin
                busy = 1'b0;
                done = 1'b0;
                error = 1'b0;
            end
            F_WAIT_ACK: begin
                busy = 1'b1;
                done = 1'b0;
                error = 1'b0;
            end
            F_DONE: begin
                busy = 1'b0;
                done = 1'b1;
                error = 1'b0;
            end
            F_ERROR: begin
                busy = 1'b0;
                done = 1'b0;
                error = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
