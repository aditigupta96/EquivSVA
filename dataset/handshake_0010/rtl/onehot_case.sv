module handshake_0010_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire peer_ack,
    output reg  waiting,
    output reg  acked,
    output reg  release
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] WAIT_ACK = 4'b0010;
    localparam [3:0] ACKED = 4'b0100;
    localparam [3:0] WAIT_RELEASE = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req) ? WAIT_ACK : ((!req) ? IDLE : (IDLE));
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
        waiting = (state == WAIT_ACK);
        acked = (state == ACKED);
        release = (state == WAIT_RELEASE);
    end
endmodule
