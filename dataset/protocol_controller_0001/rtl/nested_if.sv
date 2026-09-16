module protocol_controller_0001_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ack,
    input  wire abort,
    output wire busy,
    output wire done,
    output wire error
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_WAIT_ACK = 2'd1;
    localparam [1:0] S_DONE   = 2'd2;
    localparam [1:0] S_ERROR  = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_WAIT_ACK : ((!start) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT_ACK) begin
                state <= (abort) ? S_ERROR : ((!abort && ack) ? S_DONE : ((!abort && !ack) ? S_WAIT_ACK : (S_WAIT_ACK)));
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else if (state == S_ERROR) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_WAIT_ACK);
    assign done = (state == S_DONE);
    assign error = (state == S_ERROR);
endmodule
