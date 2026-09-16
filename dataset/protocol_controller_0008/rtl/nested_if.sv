module protocol_controller_0008_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire open_ok,
    input  wire auth_ok,
    input  wire transfer_done,
    input  wire close_ok,
    input  wire abort,
    output wire opening,
    output wire authenticating,
    output wire transferring,
    output wire closing,
    output wire done,
    output wire failed
);
    localparam [2:0] S_OPEN   = 3'd0;
    localparam [2:0] S_AUTH   = 3'd1;
    localparam [2:0] S_TRANSFER = 3'd2;
    localparam [2:0] S_CLOSE  = 3'd3;
    localparam [2:0] S_DONE   = 3'd4;
    localparam [2:0] S_FAILED = 3'd5;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_OPEN;
        end else begin
            if (state == S_OPEN) begin
                state <= (abort) ? S_FAILED : ((!abort && open_ok) ? S_AUTH : ((!abort && !open_ok) ? S_OPEN : (S_OPEN)));
            end
            else if (state == S_AUTH) begin
                state <= (abort) ? S_FAILED : ((!abort && auth_ok) ? S_TRANSFER : ((!abort && !auth_ok) ? S_AUTH : (S_AUTH)));
            end
            else if (state == S_TRANSFER) begin
                state <= (abort) ? S_FAILED : ((!abort && transfer_done) ? S_CLOSE : ((!abort && !transfer_done) ? S_TRANSFER : (S_TRANSFER)));
            end
            else if (state == S_CLOSE) begin
                state <= (abort) ? S_FAILED : ((!abort && close_ok) ? S_DONE : ((!abort && !close_ok) ? S_CLOSE : (S_CLOSE)));
            end
            else if (state == S_DONE) begin
                state <= S_OPEN;
            end
            else if (state == S_FAILED) begin
                state <= S_OPEN;
            end
            else begin
                state <= S_OPEN;
            end
        end
    end

    assign opening = (state == S_OPEN);
    assign authenticating = (state == S_AUTH);
    assign transferring = (state == S_TRANSFER);
    assign closing = (state == S_CLOSE);
    assign done = (state == S_DONE);
    assign failed = (state == S_FAILED);
endmodule
