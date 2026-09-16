module handshake_0009_mutant_force_exit_t2 (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ready,
    input  wire cancel,
    output reg  valid,
    output reg  cancelled,
    output reg  done
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] VALID = 2'd1;
    localparam [1:0] CANCEL = 2'd2;
    localparam [1:0] DONE  = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = VALID;
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
        valid = 1'b0;
        cancelled = 1'b0;
        done = 1'b0;
        case (state)
            IDLE: begin
                valid = 1'b0;
                cancelled = 1'b0;
                done = 1'b0;
            end
            VALID: begin
                valid = 1'b1;
                cancelled = 1'b0;
                done = 1'b0;
            end
            CANCEL: begin
                valid = 1'b0;
                cancelled = 1'b1;
                done = 1'b0;
            end
            DONE: begin
                valid = 1'b0;
                cancelled = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
