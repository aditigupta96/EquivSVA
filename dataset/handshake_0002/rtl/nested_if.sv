module handshake_0002_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire done,
    output wire busy,
    output wire ack
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_BUSY   = 2'd1;
    localparam [1:0] S_ACK    = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req) ? S_BUSY : (S_IDLE);
            end
            else if (state == S_BUSY) begin
                state <= (done) ? S_ACK : (S_BUSY);
            end
            else if (state == S_ACK) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_BUSY);
    assign ack = (state == S_ACK);
endmodule
