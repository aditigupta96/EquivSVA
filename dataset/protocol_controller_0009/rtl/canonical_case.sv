module protocol_controller_0009_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire open,
    input  wire transfer_done,
    input  wire close,
    output reg  opened,
    output reg  transferring,
    output reg  closed
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] OPEN  = 2'd1;
    localparam [1:0] XFER  = 2'd2;
    localparam [1:0] CLOSE = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
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
        opened = 1'b0;
        transferring = 1'b0;
        closed = 1'b0;
        case (state)
            IDLE: begin
                opened = 1'b0;
                transferring = 1'b0;
                closed = 1'b0;
            end
            OPEN: begin
                opened = 1'b1;
                transferring = 1'b0;
                closed = 1'b0;
            end
            XFER: begin
                opened = 1'b0;
                transferring = 1'b1;
                closed = 1'b0;
            end
            CLOSE: begin
                opened = 1'b0;
                transferring = 1'b0;
                closed = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
