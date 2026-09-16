module protocol_controller_0008_onehot_case (
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
    localparam [5:0] OPEN  = 6'b000001;
    localparam [5:0] AUTH  = 6'b000010;
    localparam [5:0] TRANSFER = 6'b000100;
    localparam [5:0] CLOSE = 6'b001000;
    localparam [5:0] DONE  = 6'b010000;
    localparam [5:0] FAILED = 6'b100000;

    reg [5:0] state, next_state;

    always @* begin
        next_state = OPEN;
        case (state)
            OPEN: next_state = (abort) ? FAILED : ((!abort && open_ok) ? AUTH : ((!abort && !open_ok) ? OPEN : (OPEN)));
            AUTH: next_state = (abort) ? FAILED : ((!abort && auth_ok) ? TRANSFER : ((!abort && !auth_ok) ? AUTH : (AUTH)));
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
        opening = (state == OPEN);
        authenticating = (state == AUTH);
        transferring = (state == TRANSFER);
        closing = (state == CLOSE);
        done = (state == DONE);
        failed = (state == FAILED);
    end
endmodule
