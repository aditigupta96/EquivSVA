module handshake_0010_mutant_drop_t2 (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire peer_ack,
    output reg  waiting,
    output reg  acked,
    output reg  release
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] WAIT_ACK = 2'd1;
    localparam [1:0] ACKED = 2'd2;
    localparam [1:0] WAIT_RELEASE = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (req) ? WAIT_ACK : (IDLE);
            WAIT_ACK: next_state = (peer_ack) ? ACKED : ((!peer_ack) ? WAIT_ACK : (WAIT_ACK));
            ACKED: next_state = WAIT_RELEASE;
            WAIT_RELEASE: next_state = (req) ? WAIT_RELEASE : ((!req) ? IDLE : (WAIT_RELEASE));
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
        waiting = 1'b0;
        acked = 1'b0;
        release = 1'b0;
        case (state)
            IDLE: begin
                waiting = 1'b0;
                acked = 1'b0;
                release = 1'b0;
            end
            WAIT_ACK: begin
                waiting = 1'b1;
                acked = 1'b0;
                release = 1'b0;
            end
            ACKED: begin
                waiting = 1'b0;
                acked = 1'b1;
                release = 1'b0;
            end
            WAIT_RELEASE: begin
                waiting = 1'b0;
                acked = 1'b0;
                release = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
