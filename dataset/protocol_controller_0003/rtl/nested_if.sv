module protocol_controller_0003_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire prepared,
    input  wire commit,
    input  wire abort,
    input  wire recover,
    output wire preparing,
    output wire ready_commit,
    output wire committed,
    output wire aborted
);
    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_PREPARE = 3'd1;
    localparam [2:0] S_READY  = 3'd2;
    localparam [2:0] S_COMMITTED = 3'd3;
    localparam [2:0] S_ABORTED = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_PREPARE : ((!start) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_PREPARE) begin
                state <= (abort) ? S_ABORTED : ((!abort && prepared) ? S_READY : ((!abort && !prepared) ? S_PREPARE : (S_PREPARE)));
            end
            else if (state == S_READY) begin
                state <= (abort) ? S_ABORTED : ((!abort && commit) ? S_COMMITTED : ((!abort && !commit) ? S_READY : (S_READY)));
            end
            else if (state == S_COMMITTED) begin
                state <= S_IDLE;
            end
            else if (state == S_ABORTED) begin
                state <= (recover) ? S_IDLE : ((!recover) ? S_ABORTED : (S_ABORTED));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign preparing = (state == S_PREPARE);
    assign ready_commit = (state == S_READY);
    assign committed = (state == S_COMMITTED);
    assign aborted = (state == S_ABORTED);
endmodule
