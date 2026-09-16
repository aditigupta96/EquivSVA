module protocol_controller_0008_mutant_ignore_auth (
    input  wire clk,
    input  wire rst,
    input  wire open_ok,
    input  wire auth_ok,
    input  wire transfer_done,
    input  wire close_ok,
    input  wire abort,
    output reg  opening,
    output reg  authenticating,
    output reg  transferring,
    output reg  closing,
    output reg  done,
    output reg  failed
);
    localparam [2:0] OPEN  = 3'd0;
    localparam [2:0] AUTH  = 3'd1;
    localparam [2:0] TRANSFER = 3'd2;
    localparam [2:0] CLOSE = 3'd3;
    localparam [2:0] DONE  = 3'd4;
    localparam [2:0] FAILED = 3'd5;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            OPEN: next_state = (abort) ? FAILED : ((!abort && open_ok) ? AUTH : ((!abort && !open_ok) ? OPEN : (OPEN)));
            AUTH: next_state = (abort) ? FAILED : ((!abort && !auth_ok) ? AUTH : (AUTH));
            TRANSFER: next_state = (abort) ? FAILED : ((!abort && transfer_done) ? CLOSE : ((!abort && !transfer_done) ? TRANSFER : (TRANSFER)));
            CLOSE: next_state = (abort) ? FAILED : ((!abort && close_ok) ? DONE : ((!abort && !close_ok) ? CLOSE : (CLOSE)));
            DONE: next_state = OPEN;
            FAILED: next_state = OPEN;
            default: next_state = OPEN;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= OPEN;
        else
            state <= next_state;
    end

    always @* begin
        opening = 1'b0;
        authenticating = 1'b0;
        transferring = 1'b0;
        closing = 1'b0;
        done = 1'b0;
        failed = 1'b0;
        case (state)
            OPEN: begin
                opening = 1'b1;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            AUTH: begin
                opening = 1'b0;
                authenticating = 1'b1;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            TRANSFER: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b1;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            CLOSE: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b1;
                done = 1'b0;
                failed = 1'b0;
            end
            DONE: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b1;
                failed = 1'b0;
            end
            FAILED: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
