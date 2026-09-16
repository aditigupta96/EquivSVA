module protocol_controller_0001_mutant_done_stuck (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ack,
    input  wire abort,
    output reg  busy,
    output reg  done,
    output reg  error
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] WAIT_ACK = 2'd1;
    localparam [1:0] DONE  = 2'd2;
    localparam [1:0] ERROR = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (start) ? WAIT_ACK : ((!start) ? IDLE : (IDLE));
            WAIT_ACK: next_state = (abort) ? ERROR : ((!abort && ack) ? DONE : ((!abort && !ack) ? WAIT_ACK : (WAIT_ACK)));
            DONE: next_state = DONE;
            ERROR: next_state = IDLE;
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
        done = 1'b0;
        error = 1'b0;
        case (state)
            IDLE: begin
                busy = 1'b0;
                done = 1'b0;
                error = 1'b0;
            end
            WAIT_ACK: begin
                busy = 1'b1;
                done = 1'b0;
                error = 1'b0;
            end
            DONE: begin
                busy = 1'b0;
                done = 1'b1;
                error = 1'b0;
            end
            ERROR: begin
                busy = 1'b0;
                done = 1'b0;
                error = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
