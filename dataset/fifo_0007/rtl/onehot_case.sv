module fifo_0007_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    output reg  empty,
    output reg  one,
    output reg  full
);
    localparam [2:0] EMPTY = 3'b001;
    localparam [2:0] ONE   = 3'b010;
    localparam [2:0] FULL  = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = EMPTY;
        case (state)
            EMPTY: next_state = (push) ? ONE : ((!push) ? EMPTY : (EMPTY));
            ONE: next_state = (push && !pop) ? FULL : ((pop && !push) ? EMPTY : (((push && pop) || (!push && !pop)) ? ONE : (ONE)));
            FULL: next_state = (pop) ? ONE : ((!pop) ? FULL : (FULL));
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
        empty = (state == EMPTY);
        one = (state == ONE);
        full = (state == FULL);
    end
endmodule
