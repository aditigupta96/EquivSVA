module handshake_0003_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire req,
    output reg  ack
);
    localparam [0:0] F_IDLE         = 1'd0;
    localparam [0:0] F_ACK          = 1'd1;

    reg [0:0] state, next_state;

    wire guard_idle_0 = (req);
    wire guard_ack_0 = (req);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_ACK;
                else
                    next_state = F_IDLE;
            end
            F_ACK: begin
                if (guard_ack_0)
                    next_state = F_ACK;
                else
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
        ack = 1'b0;
        case (state)
            F_IDLE: begin
                ack = 1'b0;
            end
            F_ACK: begin
                ack = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
