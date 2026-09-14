module handshake_0001_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire ready,
    input  wire cancel,
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
                state <= (req && ready) ? S_WAIT : ((!(req && ready)) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT) begin
                state <= (cancel) ? S_IDLE : ((!cancel) ? S_ACK : (S_WAIT));
            end
            else if (state == S_ACK) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_WAIT);
    assign ack = (state == S_ACK);
endmodule
