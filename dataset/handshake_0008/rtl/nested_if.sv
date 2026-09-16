module handshake_0008_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire accept,
    input  wire retry,
    output wire busy,
    output wire retrying,
    output wire done
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_WAIT   = 2'd1;
    localparam [1:0] S_RETRY  = 2'd2;
    localparam [1:0] S_DONE   = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req) ? S_WAIT : ((!req) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_WAIT) begin
                state <= (retry) ? S_RETRY : ((!retry && accept) ? S_DONE : ((!retry && !accept) ? S_WAIT : (S_WAIT)));
            end
            else if (state == S_RETRY) begin
                state <= S_WAIT;
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_WAIT);
    assign retrying = (state == S_RETRY);
    assign done = (state == S_DONE);
endmodule
