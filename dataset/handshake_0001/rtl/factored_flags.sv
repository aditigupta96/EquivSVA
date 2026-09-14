module handshake_0001_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire ready,
    input  wire cancel,
    output reg  busy,
    output reg  ack
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_WAIT         = 2'd1;
    localparam [1:0] F_ACK          = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (req && ready);
    wire guard_idle_1 = (!(req && ready));
    wire guard_wait_0 = (cancel);
    wire guard_wait_1 = (!cancel);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_WAIT;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_WAIT: begin
                if (guard_wait_0)
                    next_state = F_IDLE;
                else if (guard_wait_1)
                    next_state = F_ACK;
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
            F_WAIT: begin
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
