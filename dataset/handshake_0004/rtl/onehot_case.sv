module handshake_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire ready,
    output reg  valid
);
    localparam [1:0] EMPTY = 2'b01;
    localparam [1:0] FULL  = 2'b10;

    reg [1:0] state, next_state;

    always @* begin
        next_state = EMPTY;
        case (state)
            EMPTY: next_state = (push) ? FULL : (EMPTY);
            FULL: next_state = (ready) ? EMPTY : (FULL);
            default: next_state = EMPTY;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= EMPTY;
        else
            state <= next_state;
    end

    always @* begin
        valid = (state == FULL);
    end
endmodule
