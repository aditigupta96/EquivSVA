module handshake_0002_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire done,
    output reg  busy,
    output reg  ack
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] BUSY  = 3'b010;
    localparam [2:0] ACK   = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req) ? BUSY : (IDLE);
            BUSY: next_state = (done) ? ACK : (BUSY);
            ACK: next_state = IDLE;
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
        busy = (state == BUSY);
        ack = (state == ACK);
    end
endmodule
