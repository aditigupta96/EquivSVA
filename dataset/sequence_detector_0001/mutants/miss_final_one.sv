module sequence_detector_0001_mutant_miss_final_one (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  seen1,
    output reg  seen10,
    output reg  seen101,
    output reg  match
);
    localparam [2:0] S0    = 3'd0;
    localparam [2:0] S1    = 3'd1;
    localparam [2:0] S10   = 3'd2;
    localparam [2:0] S101  = 3'd3;
    localparam [2:0] MATCH = 3'd4;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            S0: next_state = (bit_in) ? S1 : ((!bit_in) ? S0 : (S0));
            S1: next_state = (bit_in) ? S1 : ((!bit_in) ? S10 : (S1));
            S10: next_state = (bit_in) ? S101 : ((!bit_in) ? S0 : (S10));
            S101: next_state = (!bit_in) ? S10 : (S101);
            MATCH: next_state = (bit_in) ? S1 : ((!bit_in) ? S10 : (MATCH));
            default: next_state = S0;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    always @* begin
        seen1 = 1'b0;
        seen10 = 1'b0;
        seen101 = 1'b0;
        match = 1'b0;
        case (state)
            S0: begin
                seen1 = 1'b0;
                seen10 = 1'b0;
                seen101 = 1'b0;
                match = 1'b0;
            end
            S1: begin
                seen1 = 1'b1;
                seen10 = 1'b0;
                seen101 = 1'b0;
                match = 1'b0;
            end
            S10: begin
                seen1 = 1'b0;
                seen10 = 1'b1;
                seen101 = 1'b0;
                match = 1'b0;
            end
            S101: begin
                seen1 = 1'b0;
                seen10 = 1'b0;
                seen101 = 1'b1;
                match = 1'b0;
            end
            MATCH: begin
                seen1 = 1'b0;
                seen10 = 1'b0;
                seen101 = 1'b0;
                match = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
