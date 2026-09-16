module sequence_detector_0003_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  progress1,
    output reg  progress2,
    output reg  match
);
    localparam [3:0] S0    = 4'b0001;
    localparam [3:0] S1    = 4'b0010;
    localparam [3:0] S2    = 4'b0100;
    localparam [3:0] MATCH = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = S0;
        case (state)
            S0: next_state = (!bit_in) ? S1 : ((bit_in) ? S0 : (S0));
            S1: next_state = (!bit_in) ? S2 : ((bit_in) ? S0 : (S1));
            S2: next_state = (!bit_in) ? S2 : ((bit_in) ? MATCH : (S2));
            MATCH: next_state = (!bit_in) ? S1 : ((bit_in) ? S0 : (MATCH));
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
        progress1 = (state == S1);
        progress2 = (state == S2);
        match = (state == MATCH);
    end
endmodule
