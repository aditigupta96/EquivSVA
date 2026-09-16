module sequence_detector_0001_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  seen1,
    output reg  seen10,
    output reg  seen101,
    output reg  match
);
    localparam [2:0] F_S0           = 3'd0;
    localparam [2:0] F_S1           = 3'd1;
    localparam [2:0] F_S10          = 3'd2;
    localparam [2:0] F_S101         = 3'd3;
    localparam [2:0] F_MATCH        = 3'd4;

    reg [2:0] state, next_state;

    wire guard_s0_0 = (bit_in);
    wire guard_s0_1 = (!bit_in);
    wire guard_s1_0 = (bit_in);
    wire guard_s1_1 = (!bit_in);
    wire guard_s10_0 = (bit_in);
    wire guard_s10_1 = (!bit_in);
    wire guard_s101_0 = (bit_in);
    wire guard_s101_1 = (!bit_in);
    wire guard_match_0 = (bit_in);
    wire guard_match_1 = (!bit_in);

    always @* begin
        next_state = state;
        case (state)
            F_S0: begin
                if (guard_s0_0)
                    next_state = F_S1;
                else if (guard_s0_1)
                    next_state = F_S0;
            end
            F_S1: begin
                if (guard_s1_0)
                    next_state = F_S1;
                else if (guard_s1_1)
                    next_state = F_S10;
            end
            F_S10: begin
                if (guard_s10_0)
                    next_state = F_S101;
                else if (guard_s10_1)
                    next_state = F_S0;
            end
            F_S101: begin
                if (guard_s101_0)
                    next_state = F_MATCH;
                else if (guard_s101_1)
                    next_state = F_S10;
            end
            F_MATCH: begin
                if (guard_match_0)
                    next_state = F_S1;
                else if (guard_match_1)
                    next_state = F_S10;
            end
            default: next_state = F_S0;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_S0;
        else
            state <= next_state;
    end

    always @* begin
        seen1 = 1'b0;
        seen10 = 1'b0;
        seen101 = 1'b0;
        match = 1'b0;
        case (state)
            F_S0: begin
                seen1 = 1'b0;
                seen10 = 1'b0;
                seen101 = 1'b0;
                match = 1'b0;
            end
            F_S1: begin
                seen1 = 1'b1;
                seen10 = 1'b0;
                seen101 = 1'b0;
                match = 1'b0;
            end
            F_S10: begin
                seen1 = 1'b0;
                seen10 = 1'b1;
                seen101 = 1'b0;
                match = 1'b0;
            end
            F_S101: begin
                seen1 = 1'b0;
                seen10 = 1'b0;
                seen101 = 1'b1;
                match = 1'b0;
            end
            F_MATCH: begin
                seen1 = 1'b0;
                seen10 = 1'b0;
                seen101 = 1'b0;
                match = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
