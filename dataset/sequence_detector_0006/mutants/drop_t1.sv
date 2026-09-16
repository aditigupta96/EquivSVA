module sequence_detector_0006_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output reg  progress1,
    output reg  progress2,
    output reg  progress3,
    output reg  match
);
    localparam [2:0] S0    = 3'd0;
    localparam [2:0] S1    = 3'd1;
    localparam [2:0] S2    = 3'd2;
    localparam [2:0] S3    = 3'd3;
    localparam [2:0] MATCH = 3'd4;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            S0: next_state = (bit_in) ? S0 : (S0);
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
        progress1 = 1'b0;
        progress2 = 1'b0;
        progress3 = 1'b0;
        match = 1'b0;
        case (state)
            S0: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                progress3 = 1'b0;
                match = 1'b0;
            end
            S1: begin
                progress1 = 1'b1;
                progress2 = 1'b0;
                progress3 = 1'b0;
                match = 1'b0;
            end
            S2: begin
                progress1 = 1'b0;
                progress2 = 1'b1;
                progress3 = 1'b0;
                match = 1'b0;
            end
            S3: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                progress3 = 1'b1;
                match = 1'b0;
            end
            MATCH: begin
                progress1 = 1'b0;
                progress2 = 1'b0;
                progress3 = 1'b0;
                match = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
