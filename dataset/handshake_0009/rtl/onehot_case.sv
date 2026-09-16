module handshake_0009_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ready,
    input  wire cancel,
    output reg  valid,
    output reg  cancelled,
    output reg  done
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] VALID = 4'b0010;
    localparam [3:0] CANCEL = 4'b0100;
    localparam [3:0] DONE  = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? VALID : ((!start) ? IDLE : (IDLE));
            VALID: next_state = (cancel) ? CANCEL : ((!cancel && ready) ? DONE : ((!cancel && !ready) ? VALID : (VALID)));
            CANCEL: next_state = IDLE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        valid = (state == VALID);
        cancelled = (state == CANCEL);
        done = (state == DONE);
    end
endmodule
