module fifo_0007_mutant_empty_ignores_push (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    output reg  empty,
    output reg  one,
    output reg  full
);
    localparam [1:0] EMPTY = 2'd0;
    localparam [1:0] ONE   = 2'd1;
    localparam [1:0] FULL  = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            EMPTY: next_state = (!push) ? EMPTY : (EMPTY);
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
        empty = 1'b0;
        one = 1'b0;
        full = 1'b0;
        case (state)
            EMPTY: begin
                empty = 1'b1;
                one = 1'b0;
                full = 1'b0;
            end
            ONE: begin
                empty = 1'b0;
                one = 1'b1;
                full = 1'b0;
            end
            FULL: begin
                empty = 1'b0;
                one = 1'b0;
                full = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
