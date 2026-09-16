module protocol_controller_0008_factored_flags (
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
    localparam [2:0] F_OPEN         = 3'd0;
    localparam [2:0] F_AUTH         = 3'd1;
    localparam [2:0] F_TRANSFER     = 3'd2;
    localparam [2:0] F_CLOSE        = 3'd3;
    localparam [2:0] F_DONE         = 3'd4;
    localparam [2:0] F_FAILED       = 3'd5;

    reg [2:0] state, next_state;

    wire guard_open_0 = (abort);
    wire guard_open_1 = (!abort && open_ok);
    wire guard_open_2 = (!abort && !open_ok);
    wire guard_auth_0 = (abort);
    wire guard_auth_1 = (!abort && auth_ok);
    wire guard_auth_2 = (!abort && !auth_ok);
    wire guard_transfer_0 = (abort);
    wire guard_transfer_1 = (!abort && transfer_done);
    wire guard_transfer_2 = (!abort && !transfer_done);
    wire guard_close_0 = (abort);
    wire guard_close_1 = (!abort && close_ok);
    wire guard_close_2 = (!abort && !close_ok);

    always @* begin
        next_state = state;
        case (state)
            F_OPEN: begin
                if (guard_open_0)
                    next_state = F_FAILED;
                else if (guard_open_1)
                    next_state = F_AUTH;
                else if (guard_open_2)
                    next_state = F_OPEN;
            end
            F_AUTH: begin
                if (guard_auth_0)
                    next_state = F_FAILED;
                else if (guard_auth_1)
                    next_state = F_TRANSFER;
                else if (guard_auth_2)
                    next_state = F_AUTH;
            end
            F_TRANSFER: begin
                if (guard_transfer_0)
                    next_state = F_FAILED;
                else if (guard_transfer_1)
                    next_state = F_CLOSE;
                else if (guard_transfer_2)
                    next_state = F_TRANSFER;
            end
            F_CLOSE: begin
                if (guard_close_0)
                    next_state = F_FAILED;
                else if (guard_close_1)
                    next_state = F_DONE;
                else if (guard_close_2)
                    next_state = F_CLOSE;
            end
            F_DONE: begin
                next_state = F_OPEN;
            end
            F_FAILED: begin
                next_state = F_OPEN;
            end
            default: next_state = F_OPEN;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_OPEN;
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
            F_OPEN: begin
                opening = 1'b1;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            F_AUTH: begin
                opening = 1'b0;
                authenticating = 1'b1;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            F_TRANSFER: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b1;
                closing = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            F_CLOSE: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b1;
                done = 1'b0;
                failed = 1'b0;
            end
            F_DONE: begin
                opening = 1'b0;
                authenticating = 1'b0;
                transferring = 1'b0;
                closing = 1'b0;
                done = 1'b1;
                failed = 1'b0;
            end
            F_FAILED: begin
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
