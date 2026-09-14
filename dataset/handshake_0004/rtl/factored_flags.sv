module handshake_0004_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire ready,
    output reg  valid
);
    localparam [0:0] F_EMPTY        = 1'd0;
    localparam [0:0] F_FULL         = 1'd1;

    reg [0:0] state, next_state;

    wire guard_empty_0 = (push);
    wire guard_full_0 = (ready);

    always @* begin
        next_state = state;
        case (state)
            F_EMPTY: begin
                if (guard_empty_0)
                    next_state = F_FULL;
                else
                    next_state = F_EMPTY;
            end
            F_FULL: begin
                if (guard_full_0)
                    next_state = F_EMPTY;
                else
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
        valid = 1'b0;
        case (state)
            F_EMPTY: begin
                valid = 1'b0;
            end
            F_FULL: begin
                valid = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
