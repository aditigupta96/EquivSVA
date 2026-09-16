module handshake_0008_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire accept,
    input  wire retry,
    output reg  busy,
    output reg  retrying,
    output reg  done
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] WAIT  = 4'b0010;
    localparam [3:0] RETRY = 4'b0100;
    localparam [3:0] DONE  = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req) ? WAIT : ((!req) ? IDLE : (IDLE));
            WAIT: next_state = (retry) ? RETRY : ((!retry && accept) ? DONE : ((!retry && !accept) ? WAIT : (WAIT)));
            RETRY: next_state = WAIT;
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
        busy = (state == WAIT);
        retrying = (state == RETRY);
        done = (state == DONE);
    end
endmodule
