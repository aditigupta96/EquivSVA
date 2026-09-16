module pulse_event_0009_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire complete,
    output wire waiting,
    output wire pulse,
    output wire idle
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_WAIT   = 2'd1;
    localparam [1:0] S_PULSE  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (request) ? S_WAIT : ((!request) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT) begin
                state <= (complete) ? S_PULSE : ((!complete) ? S_WAIT : (S_WAIT));
            end
            else if (state == S_PULSE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign waiting = (state == S_WAIT);
    assign pulse = (state == S_PULSE);
    assign idle = (state == S_IDLE);
endmodule
