module handshake_0002_mutant_ack_stuck (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire done,
    output reg  busy,
    output reg  ack
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] BUSY  = 2'd1;
    localparam [1:0] ACK   = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (req) ? BUSY : (IDLE);
            BUSY: next_state = (done) ? ACK : (BUSY);
            ACK: next_state = ACK;
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
        busy = 1'b0;
        ack = 1'b0;
        case (state)
            IDLE: begin
                busy = 1'b0;
                ack = 1'b0;
            end
            BUSY: begin
                busy = 1'b1;
                ack = 1'b0;
            end
            ACK: begin
                busy = 1'b0;
                ack = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
