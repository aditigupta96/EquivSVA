module handshake_0010_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire peer_ack,
    output wire waiting,
    output wire acked,
    output wire release
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_WAIT_ACK = 2'd1;
    localparam [1:0] S_ACKED  = 2'd2;
    localparam [1:0] S_WAIT_RELEASE = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req) ? S_WAIT_ACK : ((!req) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT_ACK) begin
                state <= (peer_ack) ? S_ACKED : ((!peer_ack) ? S_WAIT_ACK : (S_WAIT_ACK));
            end
            else if (state == S_ACKED) begin
                state <= S_WAIT_RELEASE;
            end
            else if (state == S_WAIT_RELEASE) begin
                state <= (req) ? S_WAIT_RELEASE : ((!req) ? S_IDLE : (S_WAIT_RELEASE));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign waiting = (state == S_WAIT_ACK);
    assign acked = (state == S_ACKED);
    assign release = (state == S_WAIT_RELEASE);
endmodule
