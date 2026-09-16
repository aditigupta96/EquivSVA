module protocol_controller_0002_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire authorized,
    input  wire complete,
    input  wire cancel,
    output wire authorizing,
    output wire executing,
    output wire done,
    output wire cancelled
);
    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_AUTH   = 3'd1;
    localparam [2:0] S_EXEC   = 3'd2;
    localparam [2:0] S_DONE   = 3'd3;
    localparam [2:0] S_CANCEL = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (request) ? S_AUTH : ((!request) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_AUTH) begin
                state <= (cancel) ? S_CANCEL : ((!cancel && authorized) ? S_EXEC : ((!cancel && !authorized) ? S_AUTH : (S_AUTH)));
            end
            else if (state == S_EXEC) begin
                state <= (cancel) ? S_CANCEL : ((!cancel && complete) ? S_DONE : ((!cancel && !complete) ? S_EXEC : (S_EXEC)));
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else if (state == S_CANCEL) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign authorizing = (state == S_AUTH);
    assign executing = (state == S_EXEC);
    assign done = (state == S_DONE);
    assign cancelled = (state == S_CANCEL);
endmodule
