module handshake_0008_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire req,
    input  wire accept,
    input  wire retry,
    output reg  busy,
    output reg  retrying,
    output reg  done
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] WAIT  = 2'd1;
    localparam [1:0] RETRY = 2'd2;
    localparam [1:0] DONE  = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (!req) ? IDLE : (IDLE);
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
        busy = 1'b0;
        retrying = 1'b0;
        done = 1'b0;
        case (state)
            IDLE: begin
                busy = 1'b0;
                retrying = 1'b0;
                done = 1'b0;
            end
            WAIT: begin
                busy = 1'b1;
                retrying = 1'b0;
                done = 1'b0;
            end
            RETRY: begin
                busy = 1'b0;
                retrying = 1'b1;
                done = 1'b0;
            end
            DONE: begin
                busy = 1'b0;
                retrying = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
