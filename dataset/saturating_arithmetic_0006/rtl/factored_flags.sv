module saturating_arithmetic_0006_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire raise,
    input  wire lower,
    output reg  low,
    output reg  nominal,
    output reg  high
);
    localparam [1:0] F_LOW          = 2'd0;
    localparam [1:0] F_NOMINAL      = 2'd1;
    localparam [1:0] F_HIGH         = 2'd2;

    reg [1:0] state, next_state;

    wire guard_low_0 = (raise && !lower);
    wire guard_low_1 = (!(raise && !lower));
    wire guard_nominal_0 = (raise && !lower);
    wire guard_nominal_1 = (lower && !raise);
    wire guard_nominal_2 = ((raise && lower) || (!raise && !lower));
    wire guard_high_0 = (lower && !raise);
    wire guard_high_1 = (!(lower && !raise));

    always @* begin
        next_state = state;
        case (state)
            F_LOW: begin
                if (guard_low_0)
                    next_state = F_NOMINAL;
                else if (guard_low_1)
                    next_state = F_LOW;
            end
            F_NOMINAL: begin
                if (guard_nominal_0)
                    next_state = F_HIGH;
                else if (guard_nominal_1)
                    next_state = F_LOW;
                else if (guard_nominal_2)
                    next_state = F_NOMINAL;
            end
            F_HIGH: begin
                if (guard_high_0)
                    next_state = F_NOMINAL;
                else if (guard_high_1)
                    next_state = F_HIGH;
            end
            default: next_state = F_NOMINAL;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_NOMINAL;
        else
            state <= next_state;
    end

    always @* begin
        low = 1'b0;
        nominal = 1'b0;
        high = 1'b0;
        case (state)
            F_LOW: begin
                low = 1'b1;
                nominal = 1'b0;
                high = 1'b0;
            end
            F_NOMINAL: begin
                low = 1'b0;
                nominal = 1'b1;
                high = 1'b0;
            end
            F_HIGH: begin
                low = 1'b0;
                nominal = 1'b0;
                high = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
