module pulse_event_0001_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output wire pulse,
    output wire armed
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_FIRE   = 2'd1;
    localparam [1:0] S_WAIT_LOW = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (event_in) ? S_FIRE : ((!event_in) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_FIRE) begin
                state <= S_WAIT_LOW;
            end
            else if (state == S_WAIT_LOW) begin
                state <= (event_in) ? S_WAIT_LOW : ((!event_in) ? S_IDLE : (S_WAIT_LOW));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign pulse = (state == S_FIRE);
    assign armed = (state == S_IDLE);
endmodule
