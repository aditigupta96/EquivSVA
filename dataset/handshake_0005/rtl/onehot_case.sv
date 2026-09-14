module handshake_0005_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire grant,
    output reg  pending,
    output reg  ack
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] WAIT  = 3'b010;
    localparam [2:0] ACK   = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req) ? WAIT : (IDLE);
            WAIT: next_state = (grant) ? ACK : (WAIT);
            ACK: next_state = (!req) ? IDLE : (ACK);
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
        pending = (state == WAIT);
        ack = (state == ACK);
    end
endmodule
