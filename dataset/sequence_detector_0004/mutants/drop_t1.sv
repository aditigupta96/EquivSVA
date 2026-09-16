module sequence_detector_0004_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  progress1,
    output reg  progress2,
    output reg  match
);
    localparam [1:0] S0    = 2'd0;
    localparam [1:0] S1    = 2'd1;
    localparam [1:0] S2    = 2'd2;
    localparam [1:0] MATCH = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            S0: next_state = (bit_in) ? S1 : (S0);
            S1: next_state = (!bit_in) ? S2 : ((bit_in) ? S1 : (S1));
            S2: next_state = (!bit_in) ? S0 : ((bit_in) ? MATCH : (S2));
            MATCH: next_state = (!bit_in) ? S2 : ((bit_in) ? S1 : (MATCH));
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
        progress1 = 1'b0;
        progress2 = 1'b0;
        match = 1'b0;
        case (state)
            S0: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                match = 1'b0;
            end
            S1: begin
                progress1 = 1'b1;
                progress2 = 1'b0;
                match = 1'b0;
            end
            S2: begin
                progress1 = 1'b0;
                progress2 = 1'b1;
                match = 1'b0;
            end
            MATCH: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                match = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
