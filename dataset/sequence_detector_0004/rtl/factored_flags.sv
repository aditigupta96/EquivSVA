module sequence_detector_0004_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  progress1,
    output reg  progress2,
    output reg  match
);
    localparam [1:0] F_S0           = 2'd0;
    localparam [1:0] F_S1           = 2'd1;
    localparam [1:0] F_S2           = 2'd2;
    localparam [1:0] F_MATCH        = 2'd3;

    reg [1:0] state, next_state;

    wire guard_s0_0 = (!bit_in);
    wire guard_s0_1 = (bit_in);
    wire guard_s1_0 = (!bit_in);
    wire guard_s1_1 = (bit_in);
    wire guard_s2_0 = (!bit_in);
    wire guard_s2_1 = (bit_in);
    wire guard_match_0 = (!bit_in);
    wire guard_match_1 = (bit_in);

    always @* begin
        next_state = state;
        case (state)
            F_S0: begin
                if (guard_s0_0)
                    next_state = F_S0;
                else if (guard_s0_1)
                    next_state = F_S1;
            end
            F_S1: begin
                if (guard_s1_0)
                    next_state = F_S2;
                else if (guard_s1_1)
                    next_state = F_S1;
            end
            F_S2: begin
                if (guard_s2_0)
                    next_state = F_S0;
                else if (guard_s2_1)
                    next_state = F_MATCH;
            end
            F_MATCH: begin
                if (guard_match_0)
                    next_state = F_S2;
                else if (guard_match_1)
                    next_state = F_S1;
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
        progress1 = 1'b0;
        progress2 = 1'b0;
        match = 1'b0;
        case (state)
            F_S0: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                match = 1'b0;
            end
            F_S1: begin
                progress1 = 1'b1;
                progress2 = 1'b0;
                match = 1'b0;
            end
            F_S2: begin
                progress1 = 1'b0;
                progress2 = 1'b1;
                match = 1'b0;
            end
            F_MATCH: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                match = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
