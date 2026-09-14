module handshake_0003_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req,
    output wire ack
);
    localparam [0:0] S_IDLE   = 1'd0;
    localparam [0:0] S_ACK    = 1'd1;

    reg [0:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req) ? S_ACK : (S_IDLE);
            end
            else if (state == S_ACK) begin
                state <= (req) ? S_ACK : (S_IDLE);
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign ack = (state == S_ACK);
endmodule
