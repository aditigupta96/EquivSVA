module handshake_0004_mutant_drop_without_ready (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire ready,
    output reg  valid
);
    localparam [0:0] EMPTY = 1'd0;
    localparam [0:0] FULL  = 1'd1;

    reg [0:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            EMPTY: next_state = (push) ? FULL : (EMPTY);
            FULL: next_state = EMPTY;
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
        valid = 1'b0;
        case (state)
            EMPTY: begin
                valid = 1'b0;
            end
            FULL: begin
                valid = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
