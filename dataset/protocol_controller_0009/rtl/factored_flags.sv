module protocol_controller_0009_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire open,
    input  wire transfer_done,
    input  wire close,
    output reg  opened,
    output reg  transferring,
    output reg  closed
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_OPEN         = 2'd1;
    localparam [1:0] F_XFER         = 2'd2;
    localparam [1:0] F_CLOSE        = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (open);
    wire guard_idle_1 = (!open);
    wire guard_xfer_0 = (transfer_done);
    wire guard_xfer_1 = (!transfer_done);
    wire guard_close_0 = (close);
    wire guard_close_1 = (!close);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_OPEN;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_OPEN: begin
                next_state = F_XFER;
            end
            F_XFER: begin
                if (guard_xfer_0)
                    next_state = F_CLOSE;
                else if (guard_xfer_1)
                    next_state = F_XFER;
            end
            F_CLOSE: begin
                if (guard_close_0)
                    next_state = F_IDLE;
                else if (guard_close_1)
                    next_state = F_CLOSE;
            end
            default: next_state = F_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        opened = 1'b0;
        transferring = 1'b0;
        closed = 1'b0;
        case (state)
            F_IDLE: begin
                opened = 1'b0;
                transferring = 1'b0;
                closed = 1'b0;
            end
            F_OPEN: begin
                opened = 1'b1;
                transferring = 1'b0;
                closed = 1'b0;
            end
            F_XFER: begin
                opened = 1'b0;
                transferring = 1'b1;
                closed = 1'b0;
            end
            F_CLOSE: begin
                opened = 1'b0;
                transferring = 1'b0;
                closed = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
