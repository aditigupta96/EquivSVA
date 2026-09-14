module handshake_0003_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req,
    output reg  ack
);
    localparam [1:0] IDLE  = 2'b01;
    localparam [1:0] ACK   = 2'b10;

    reg [1:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req) ? ACK : (IDLE);
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
        ack = (state == ACK);
    end
endmodule
