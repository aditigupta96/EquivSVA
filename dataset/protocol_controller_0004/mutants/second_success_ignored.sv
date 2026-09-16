module protocol_controller_0004_mutant_second_success_ignored (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire success,
    input  wire retry,
    input  wire reset_fail,
    output reg  attempting,
    output reg  retrying,
    output reg  done,
    output reg  failed
);
    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] ATTEMPT1 = 3'd1;
    localparam [2:0] RETRY = 3'd2;
    localparam [2:0] ATTEMPT2 = 3'd3;
    localparam [2:0] DONE  = 3'd4;
    localparam [2:0] FAILED = 3'd5;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (start) ? ATTEMPT1 : ((!start) ? IDLE : (IDLE));
            ATTEMPT1: next_state = (success) ? DONE : ((!success && retry) ? RETRY : ((!success && !retry) ? FAILED : (ATTEMPT1)));
            RETRY: next_state = ATTEMPT2;
            ATTEMPT2: next_state = (!success) ? FAILED : (ATTEMPT2);
            DONE: next_state = IDLE;
            FAILED: next_state = (reset_fail) ? IDLE : ((!reset_fail) ? FAILED : (FAILED));
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
        attempting = 1'b0;
        retrying = 1'b0;
        done = 1'b0;
        failed = 1'b0;
        case (state)
            IDLE: begin
                attempting = 1'b0;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            ATTEMPT1: begin
                attempting = 1'b1;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            RETRY: begin
                attempting = 1'b0;
                retrying = 1'b1;
                done = 1'b0;
                failed = 1'b0;
            end
            ATTEMPT2: begin
                attempting = 1'b1;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            DONE: begin
                attempting = 1'b0;
                retrying = 1'b0;
                done = 1'b1;
                failed = 1'b0;
            end
            FAILED: begin
                attempting = 1'b0;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
