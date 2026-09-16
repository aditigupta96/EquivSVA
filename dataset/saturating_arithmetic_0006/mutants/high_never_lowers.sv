module saturating_arithmetic_0006_mutant_high_never_lowers (
    input  wire clk,
    input  wire rst,
    input  wire raise,
    input  wire lower,
    output reg  low,
    output reg  nominal,
    output reg  high
);
    localparam [1:0] LOW   = 2'd0;
    localparam [1:0] NOMINAL = 2'd1;
    localparam [1:0] HIGH  = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            LOW: next_state = (raise && !lower) ? NOMINAL : ((!(raise && !lower)) ? LOW : (LOW));
            NOMINAL: next_state = (raise && !lower) ? HIGH : ((lower && !raise) ? LOW : (((raise && lower) || (!raise && !lower)) ? NOMINAL : (NOMINAL)));
            HIGH: next_state = (!(lower && !raise)) ? HIGH : (HIGH);
            default: next_state = NOMINAL;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= NOMINAL;
        else
            state <= next_state;
    end

    always @* begin
        low = 1'b0;
        nominal = 1'b0;
        high = 1'b0;
        case (state)
            LOW: begin
                low = 1'b1;
                nominal = 1'b0;
                high = 1'b0;
            end
            NOMINAL: begin
                low = 1'b0;
                nominal = 1'b1;
                high = 1'b0;
            end
            HIGH: begin
                low = 1'b0;
                nominal = 1'b0;
                high = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
