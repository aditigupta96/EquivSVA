module sequence_detector_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  progress1,
    output reg  progress2,
    output reg  progress3,
    output reg  match
);
    localparam [4:0] S0    = 5'b00001;
    localparam [4:0] S1    = 5'b00010;
    localparam [4:0] S2    = 5'b00100;
    localparam [4:0] S3    = 5'b01000;
    localparam [4:0] MATCH = 5'b10000;

    reg [4:0] state, next_state;

    always @* begin
        next_state = S0;
        case (state)
            S0: next_state = (!bit_in) ? S1 : ((bit_in) ? S0 : (S0));
            S1: next_state = (!bit_in) ? S1 : ((bit_in) ? S2 : (S1));
            S2: next_state = (!bit_in) ? S3 : ((bit_in) ? S0 : (S2));
            S3: next_state = (!bit_in) ? S1 : ((bit_in) ? MATCH : (S3));
            MATCH: next_state = (!bit_in) ? S3 : ((bit_in) ? S0 : (MATCH));
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
        progress3 = (state == S3);
        match = (state == MATCH);
    end
endmodule
