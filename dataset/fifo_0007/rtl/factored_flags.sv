module fifo_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    output reg  empty,
    output reg  one,
    output reg  full
);
    localparam [1:0] F_EMPTY        = 2'd0;
    localparam [1:0] F_ONE          = 2'd1;
    localparam [1:0] F_FULL         = 2'd2;

    reg [1:0] state, next_state;

    wire guard_empty_0 = (push);
    wire guard_empty_1 = (!push);
    wire guard_one_0 = (push && !pop);
    wire guard_one_1 = (pop && !push);
    wire guard_one_2 = ((push && pop) || (!push && !pop));
    wire guard_full_0 = (pop);
    wire guard_full_1 = (!pop);

    always @* begin
        next_state = state;
        case (state)
            F_EMPTY: begin
                if (guard_empty_0)
                    next_state = F_ONE;
                else if (guard_empty_1)
                    next_state = F_EMPTY;
            end
            F_ONE: begin
                if (guard_one_0)
                    next_state = F_FULL;
                else if (guard_one_1)
                    next_state = F_EMPTY;
                else if (guard_one_2)
                    next_state = F_ONE;
            end
            F_FULL: begin
                if (guard_full_0)
                    next_state = F_ONE;
                else if (guard_full_1)
                    next_state = F_FULL;
            end
            default: next_state = F_EMPTY;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_EMPTY;
        else
            state <= next_state;
    end

    always @* begin
        empty = 1'b0;
        one = 1'b0;
        full = 1'b0;
        case (state)
            F_EMPTY: begin
                empty = 1'b1;
                one = 1'b0;
                full = 1'b0;
            end
            F_ONE: begin
                empty = 1'b0;
                one = 1'b1;
                full = 1'b0;
            end
            F_FULL: begin
                empty = 1'b0;
                one = 1'b0;
                full = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
