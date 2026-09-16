module pulse_event_0003_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output wire waiting_high,
    output wire pulse,
    output wire waiting_low
);
    localparam [1:0] S_WAIT_HIGH = 2'd0;
    localparam [1:0] S_PULSE  = 2'd1;
    localparam [1:0] S_WAIT_LOW = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_WAIT_HIGH;
        end else begin
            if (state == S_WAIT_HIGH) begin
                state <= (event_in) ? S_WAIT_LOW : ((!event_in) ? S_WAIT_HIGH : (S_WAIT_HIGH));
            end
            else if (state == S_PULSE) begin
                state <= S_WAIT_HIGH;
            end
            else if (state == S_WAIT_LOW) begin
                state <= (!event_in) ? S_PULSE : ((event_in) ? S_WAIT_LOW : (S_WAIT_LOW));
            end
            else begin
                state <= S_WAIT_HIGH;
            end
        end
    end

    assign waiting_high = (state == S_WAIT_HIGH);
    assign pulse = (state == S_PULSE);
    assign waiting_low = (state == S_WAIT_LOW);
endmodule
