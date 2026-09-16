module protocol_controller_0009_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire open,
    input  wire transfer_done,
    input  wire close,
    output reg  opened,
    output reg  transferring,
    output reg  closed
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] OPEN  = 4'b0010;
    localparam [3:0] XFER  = 4'b0100;
    localparam [3:0] CLOSE = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (open) ? OPEN : ((!open) ? IDLE : (IDLE));
            OPEN: next_state = XFER;
            XFER: next_state = (transfer_done) ? CLOSE : ((!transfer_done) ? XFER : (XFER));
            CLOSE: next_state = (close) ? IDLE : ((!close) ? CLOSE : (CLOSE));
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
        opened = (state == OPEN);
        transferring = (state == XFER);
        closed = (state == CLOSE);
    end
endmodule
