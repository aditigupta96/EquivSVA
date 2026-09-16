module handshake_0010_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire peer_ack,
    output reg  waiting,
    output reg  acked,
    output reg  release
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_WAIT_ACK     = 2'd1;
    localparam [1:0] F_ACKED        = 2'd2;
    localparam [1:0] F_WAIT_RELEASE = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (req);
    wire guard_idle_1 = (!req);
    wire guard_wait_ack_0 = (peer_ack);
    wire guard_wait_ack_1 = (!peer_ack);
    wire guard_wait_release_0 = (req);
    wire guard_wait_release_1 = (!req);

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
                    next_state = F_ACKED;
                else if (guard_wait_ack_1)
                    next_state = F_WAIT_ACK;
            end
            F_ACKED: begin
                next_state = F_WAIT_RELEASE;
            end
            F_WAIT_RELEASE: begin
                if (guard_wait_release_0)
                    next_state = F_WAIT_RELEASE;
                else if (guard_wait_release_1)
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
        waiting = 1'b0;
        acked = 1'b0;
        release = 1'b0;
        case (state)
            F_IDLE: begin
                waiting = 1'b0;
                acked = 1'b0;
                release = 1'b0;
            end
            F_WAIT_ACK: begin
                waiting = 1'b1;
                acked = 1'b0;
                release = 1'b0;
            end
            F_ACKED: begin
                waiting = 1'b0;
                acked = 1'b1;
                release = 1'b0;
            end
            F_WAIT_RELEASE: begin
                waiting = 1'b0;
                acked = 1'b0;
                release = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
