module sequence_detector_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output wire progress1,
    output wire progress2,
    output wire match
);
    localparam [1:0] S_S0     = 2'd0;
    localparam [1:0] S_S1     = 2'd1;
    localparam [1:0] S_S2     = 2'd2;
    localparam [1:0] S_MATCH  = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_S0;
        end else begin
            if (state == S_S0) begin
                state <= (!bit_in) ? S_S0 : ((bit_in) ? S_S1 : (S_S0));
            end
            else if (state == S_S1) begin
                state <= (!bit_in) ? S_S2 : ((bit_in) ? S_S1 : (S_S1));
            end
            else if (state == S_S2) begin
                state <= (!bit_in) ? S_S0 : ((bit_in) ? S_MATCH : (S_S2));
            end
            else if (state == S_MATCH) begin
                state <= (!bit_in) ? S_S2 : ((bit_in) ? S_S1 : (S_MATCH));
            end
            else begin
                state <= S_S0;
            end
        end
    end

    assign progress1 = (state == S_S1);
    assign progress2 = (state == S_S2);
    assign match = (state == S_MATCH);
endmodule
