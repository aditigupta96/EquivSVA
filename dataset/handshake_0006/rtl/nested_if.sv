module handshake_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire accept,
    output wire busy,
    output wire ack
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_WAIT   = 2'd1;
    localparam [1:0] S_ACK    = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req) ? S_WAIT : ((!req) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT) begin
                state <= (accept) ? S_ACK : ((!accept) ? S_WAIT : (S_WAIT));
            end
            else if (state == S_ACK) begin
                state <= (req) ? S_ACK : ((!req) ? S_IDLE : (S_ACK));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_WAIT);
    assign ack = (state == S_ACK);
endmodule
