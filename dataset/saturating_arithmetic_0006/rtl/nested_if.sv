module saturating_arithmetic_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire raise,
    input  wire lower,
    output wire low,
    output wire nominal,
    output wire high
);
    localparam [1:0] S_LOW    = 2'd0;
    localparam [1:0] S_NOMINAL = 2'd1;
    localparam [1:0] S_HIGH   = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_NOMINAL;
        end else begin
            if (state == S_LOW) begin
                state <= (raise && !lower) ? S_NOMINAL : ((!(raise && !lower)) ? S_LOW : (S_LOW));
            end
            else if (state == S_NOMINAL) begin
                state <= (raise && !lower) ? S_HIGH : ((lower && !raise) ? S_LOW : (((raise && lower) || (!raise && !lower)) ? S_NOMINAL : (S_NOMINAL)));
            end
            else if (state == S_HIGH) begin
                state <= (lower && !raise) ? S_NOMINAL : ((!(lower && !raise)) ? S_HIGH : (S_HIGH));
            end
            else begin
                state <= S_NOMINAL;
            end
        end
    end

    assign low = (state == S_LOW);
    assign nominal = (state == S_NOMINAL);
    assign high = (state == S_HIGH);
endmodule
