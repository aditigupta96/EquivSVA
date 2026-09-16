module rate_limiter_0010_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire violation,
    input  wire clear,
    output reg  clean,
    output reg  strike1,
    output reg  strike2,
    output reg  blocked
);
    localparam [3:0] CLEAN = 4'b0001;
    localparam [3:0] S1    = 4'b0010;
    localparam [3:0] S2    = 4'b0100;
    localparam [3:0] BLOCKED = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = CLEAN;
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
        clean = (state == CLEAN);
        strike1 = (state == S1);
        strike2 = (state == S2);
        blocked = (state == BLOCKED);
    end
endmodule
