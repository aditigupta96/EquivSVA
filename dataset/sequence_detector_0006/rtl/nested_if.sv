module sequence_detector_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output wire progress1,
    output wire progress2,
    output wire progress3,
    output wire match
);
    localparam [2:0] S_S0     = 3'd0;
    localparam [2:0] S_S1     = 3'd1;
    localparam [2:0] S_S2     = 3'd2;
    localparam [2:0] S_S3     = 3'd3;
    localparam [2:0] S_MATCH  = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_S0;
        end else begin
            if (state == S_S0) begin
                state <= (!bit_in) ? S_S1 : ((bit_in) ? S_S0 : (S_S0));
            end
            else if (state == S_S1) begin
                state <= (!bit_in) ? S_S1 : ((bit_in) ? S_S2 : (S_S1));
            end
            else if (state == S_S2) begin
                state <= (!bit_in) ? S_S3 : ((bit_in) ? S_S0 : (S_S2));
            end
            else if (state == S_S3) begin
                state <= (!bit_in) ? S_S1 : ((bit_in) ? S_MATCH : (S_S3));
            end
            else if (state == S_MATCH) begin
                state <= (!bit_in) ? S_S3 : ((bit_in) ? S_S0 : (S_MATCH));
            end
            else begin
                state <= S_S0;
            end
        end
    end

    assign progress1 = (state == S_S1);
    assign progress2 = (state == S_S2);
    assign progress3 = (state == S_S3);
    assign match = (state == S_MATCH);
endmodule
