module protocol_controller_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire acquire,
    input  wire release,
    output wire waiting,
    output wire held
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_WAIT   = 2'd1;
    localparam [1:0] S_HELD   = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (acquire) ? S_WAIT : ((!acquire) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT) begin
                state <= (acquire) ? S_HELD : ((!acquire) ? S_WAIT : (S_WAIT));
            end
            else if (state == S_HELD) begin
                state <= (release) ? S_IDLE : ((!release) ? S_HELD : (S_HELD));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign waiting = (state == S_WAIT);
    assign held = (state == S_HELD);
endmodule
