module protocol_controller_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire success,
    input  wire retry,
    input  wire reset_fail,
    output wire attempting,
    output wire retrying,
    output wire done,
    output wire failed
);
    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_ATTEMPT1 = 3'd1;
    localparam [2:0] S_RETRY  = 3'd2;
    localparam [2:0] S_ATTEMPT2 = 3'd3;
    localparam [2:0] S_DONE   = 3'd4;
    localparam [2:0] S_FAILED = 3'd5;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_ATTEMPT1 : ((!start) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_ATTEMPT1) begin
                state <= (success) ? S_DONE : ((!success && retry) ? S_RETRY : ((!success && !retry) ? S_FAILED : (S_ATTEMPT1)));
            end
            else if (state == S_RETRY) begin
                state <= S_ATTEMPT2;
            end
            else if (state == S_ATTEMPT2) begin
                state <= (success) ? S_DONE : ((!success) ? S_FAILED : (S_ATTEMPT2));
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else if (state == S_FAILED) begin
                state <= (reset_fail) ? S_IDLE : ((!reset_fail) ? S_FAILED : (S_FAILED));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign attempting = (state == S_ATTEMPT1) || (state == S_ATTEMPT2);
    assign retrying = (state == S_RETRY);
    assign done = (state == S_DONE);
    assign failed = (state == S_FAILED);
endmodule
