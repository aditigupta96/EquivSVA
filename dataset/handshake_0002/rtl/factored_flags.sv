module handshake_0002_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire done,
    output reg  busy,
    output reg  ack
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_BUSY         = 2'd1;
    localparam [1:0] F_ACK          = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (req);
    wire guard_busy_0 = (done);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_BUSY;
                else
                    next_state = F_IDLE;
            end
            F_BUSY: begin
                if (guard_busy_0)
                    next_state = F_ACK;
                else
                    next_state = F_BUSY;
            end
            F_ACK: begin
                next_state = F_IDLE;
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
        busy = 1'b0;
        ack = 1'b0;
        case (state)
            F_IDLE: begin
                busy = 1'b0;
                ack = 1'b0;
            end
            F_BUSY: begin
                busy = 1'b1;
                ack = 1'b0;
            end
            F_ACK: begin
                busy = 1'b0;
                ack = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
