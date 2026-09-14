module handshake_0003_mutant_spurious_ack (
    input  wire clk,
    input  wire rst,
    input  wire req,
    output reg  ack
);
    localparam [0:0] IDLE  = 1'd0;
    localparam [0:0] ACK   = 1'd1;

    reg [0:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = ACK;
            ACK: next_state = (req) ? ACK : (IDLE);
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
        ack = 1'b0;
        case (state)
            IDLE: begin
                ack = 1'b0;
            end
            ACK: begin
                ack = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
