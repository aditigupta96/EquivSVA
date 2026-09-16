module sequence_detector_0001_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  seen1,
    output reg  seen10,
    output reg  seen101,
    output reg  match
);
    localparam [4:0] S0    = 5'b00001;
    localparam [4:0] S1    = 5'b00010;
    localparam [4:0] S10   = 5'b00100;
    localparam [4:0] S101  = 5'b01000;
    localparam [4:0] MATCH = 5'b10000;

    reg [4:0] state, next_state;

    always @* begin
        next_state = S0;
        case (state)
            S0: next_state = (bit_in) ? S1 : ((!bit_in) ? S0 : (S0));
            S1: next_state = (bit_in) ? S1 : ((!bit_in) ? S10 : (S1));
            S10: next_state = (bit_in) ? S101 : ((!bit_in) ? S0 : (S10));
            S101: next_state = (bit_in) ? MATCH : ((!bit_in) ? S10 : (S101));
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
        seen1 = (state == S1);
        seen10 = (state == S10);
        seen101 = (state == S101);
        match = (state == MATCH);
    end
endmodule
