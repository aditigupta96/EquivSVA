module handshake_0009_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ready,
    input  wire cancel,
    output wire valid,
    output wire cancelled,
    output wire done
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_VALID  = 2'd1;
    localparam [1:0] S_CANCEL = 2'd2;
    localparam [1:0] S_DONE   = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_VALID : ((!start) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_VALID) begin
                state <= (cancel) ? S_CANCEL : ((!cancel && ready) ? S_DONE : ((!cancel && !ready) ? S_VALID : (S_VALID)));
            end
            else if (state == S_CANCEL) begin
                state <= S_IDLE;
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign valid = (state == S_VALID);
    assign cancelled = (state == S_CANCEL);
    assign done = (state == S_DONE);
endmodule
