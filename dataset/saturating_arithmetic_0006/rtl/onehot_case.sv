module saturating_arithmetic_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire raise,
    input  wire lower,
    output reg  low,
    output reg  nominal,
    output reg  high
);
    localparam [2:0] LOW   = 3'b001;
    localparam [2:0] NOMINAL = 3'b010;
    localparam [2:0] HIGH  = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = NOMINAL;
        case (state)
            LOW: next_state = (raise && !lower) ? NOMINAL : ((!(raise && !lower)) ? LOW : (LOW));
            NOMINAL: next_state = (raise && !lower) ? HIGH : ((lower && !raise) ? LOW : (((raise && lower) || (!raise && !lower)) ? NOMINAL : (NOMINAL)));
            HIGH: next_state = (lower && !raise) ? NOMINAL : ((!(lower && !raise)) ? HIGH : (HIGH));
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
        low = (state == LOW);
        nominal = (state == NOMINAL);
        high = (state == HIGH);
    end
endmodule
