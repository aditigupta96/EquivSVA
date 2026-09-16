module sequence_detector_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  progress1,
    output reg  progress2,
    output reg  progress3,
    output reg  match
);
    localparam [2:0] F_S0           = 3'd0;
    localparam [2:0] F_S1           = 3'd1;
    localparam [2:0] F_S2           = 3'd2;
    localparam [2:0] F_S3           = 3'd3;
    localparam [2:0] F_MATCH        = 3'd4;

    reg [2:0] state, next_state;

    wire guard_s0_0 = (!bit_in);
    wire guard_s0_1 = (bit_in);
    wire guard_s1_0 = (!bit_in);
    wire guard_s1_1 = (bit_in);
    wire guard_s2_0 = (!bit_in);
    wire guard_s2_1 = (bit_in);
    wire guard_s3_0 = (!bit_in);
    wire guard_s3_1 = (bit_in);
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
                    next_state = F_S3;
                else if (guard_s2_1)
                    next_state = F_S1;
            end
            F_S3: begin
                if (guard_s3_0)
                    next_state = F_S0;
                else if (guard_s3_1)
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
        progress3 = 1'b0;
        match = 1'b0;
        case (state)
            F_S0: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                progress3 = 1'b0;
                match = 1'b0;
            end
            F_S1: begin
                progress1 = 1'b1;
                progress2 = 1'b0;
                progress3 = 1'b0;
                match = 1'b0;
            end
            F_S2: begin
                progress1 = 1'b0;
                progress2 = 1'b1;
                progress3 = 1'b0;
                match = 1'b0;
            end
            F_S3: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                progress3 = 1'b1;
                match = 1'b0;
            end
            F_MATCH: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                progress3 = 1'b0;
                match = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
