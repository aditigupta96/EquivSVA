module protocol_controller_0004_factored_flags (
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
    localparam [2:0] F_IDLE         = 3'd0;
    localparam [2:0] F_ATTEMPT1     = 3'd1;
    localparam [2:0] F_RETRY        = 3'd2;
    localparam [2:0] F_ATTEMPT2     = 3'd3;
    localparam [2:0] F_DONE         = 3'd4;
    localparam [2:0] F_FAILED       = 3'd5;

    reg [2:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_idle_1 = (!start);
    wire guard_attempt1_0 = (success);
    wire guard_attempt1_1 = (!success && retry);
    wire guard_attempt1_2 = (!success && !retry);
    wire guard_attempt2_0 = (success);
    wire guard_attempt2_1 = (!success);
    wire guard_failed_0 = (reset_fail);
    wire guard_failed_1 = (!reset_fail);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_ATTEMPT1;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_ATTEMPT1: begin
                if (guard_attempt1_0)
                    next_state = F_DONE;
                else if (guard_attempt1_1)
                    next_state = F_RETRY;
                else if (guard_attempt1_2)
                    next_state = F_FAILED;
            end
            F_RETRY: begin
                next_state = F_ATTEMPT2;
            end
            F_ATTEMPT2: begin
                if (guard_attempt2_0)
                    next_state = F_DONE;
                else if (guard_attempt2_1)
                    next_state = F_FAILED;
            end
            F_DONE: begin
                next_state = F_IDLE;
            end
            F_FAILED: begin
                if (guard_failed_0)
                    next_state = F_IDLE;
                else if (guard_failed_1)
                    next_state = F_FAILED;
            end
            default: next_state = F_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        attempting = 1'b0;
        retrying = 1'b0;
        done = 1'b0;
        failed = 1'b0;
        case (state)
            F_IDLE: begin
                attempting = 1'b0;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            F_ATTEMPT1: begin
                attempting = 1'b1;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            F_RETRY: begin
                attempting = 1'b0;
                retrying = 1'b1;
                done = 1'b0;
                failed = 1'b0;
            end
            F_ATTEMPT2: begin
                attempting = 1'b1;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b0;
            end
            F_DONE: begin
                attempting = 1'b0;
                retrying = 1'b0;
                done = 1'b1;
                failed = 1'b0;
            end
            F_FAILED: begin
                attempting = 1'b0;
                retrying = 1'b0;
                done = 1'b0;
                failed = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
