module protocol_controller_0009_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire open,
    input  wire transfer_done,
    input  wire close,
    output wire opened,
    output wire transferring,
    output wire closed
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_OPEN   = 2'd1;
    localparam [1:0] S_XFER   = 2'd2;
    localparam [1:0] S_CLOSE  = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (open) ? S_OPEN : ((!open) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_OPEN) begin
                state <= S_XFER;
            end
            else if (state == S_XFER) begin
                state <= (transfer_done) ? S_CLOSE : ((!transfer_done) ? S_XFER : (S_XFER));
            end
            else if (state == S_CLOSE) begin
                state <= (close) ? S_IDLE : ((!close) ? S_CLOSE : (S_CLOSE));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign opened = (state == S_OPEN);
    assign transferring = (state == S_XFER);
    assign closed = (state == S_CLOSE);
endmodule
