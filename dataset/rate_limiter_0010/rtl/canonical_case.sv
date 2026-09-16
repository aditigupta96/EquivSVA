module rate_limiter_0010_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire violation,
    input  wire clear,
    output reg  clean,
    output reg  strike1,
    output reg  strike2,
    output reg  blocked
);
    localparam [1:0] CLEAN = 2'd0;
    localparam [1:0] S1    = 2'd1;
    localparam [1:0] S2    = 2'd2;
    localparam [1:0] BLOCKED = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            CLEAN: next_state = (violation) ? S1 : ((!violation) ? CLEAN : (CLEAN));
            S1: next_state = (violation) ? S2 : ((!violation) ? CLEAN : (S1));
            S2: next_state = (violation) ? BLOCKED : ((!violation) ? CLEAN : (S2));
            BLOCKED: next_state = (clear) ? CLEAN : ((!clear) ? BLOCKED : (BLOCKED));
            default: next_state = CLEAN;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= CLEAN;
        else
            state <= next_state;
    end

    always @* begin
        clean = 1'b0;
        strike1 = 1'b0;
        strike2 = 1'b0;
        blocked = 1'b0;
        case (state)
            CLEAN: begin
                clean = 1'b1;
                strike1 = 1'b0;
                strike2 = 1'b0;
                blocked = 1'b0;
            end
            S1: begin
                clean = 1'b0;
                strike1 = 1'b1;
                strike2 = 1'b0;
                blocked = 1'b0;
            end
            S2: begin
                clean = 1'b0;
                strike1 = 1'b0;
                strike2 = 1'b1;
                blocked = 1'b0;
            end
            BLOCKED: begin
                clean = 1'b0;
                strike1 = 1'b0;
                strike2 = 1'b0;
                blocked = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
