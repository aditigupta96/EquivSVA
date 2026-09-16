module handshake_0009_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ready,
    input  wire cancel,
    output reg  valid,
    output reg  cancelled,
    output reg  done
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_VALID        = 2'd1;
    localparam [1:0] F_CANCEL       = 2'd2;
    localparam [1:0] F_DONE         = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_idle_1 = (!start);
    wire guard_valid_0 = (cancel);
    wire guard_valid_1 = (!cancel && ready);
    wire guard_valid_2 = (!cancel && !ready);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_VALID;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_VALID: begin
                if (guard_valid_0)
                    next_state = F_CANCEL;
                else if (guard_valid_1)
                    next_state = F_DONE;
                else if (guard_valid_2)
                    next_state = F_VALID;
            end
            F_CANCEL: begin
                next_state = F_IDLE;
            end
            F_DONE: begin
                next_state = F_IDLE;
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
        valid = 1'b0;
        cancelled = 1'b0;
        done = 1'b0;
        case (state)
            F_IDLE: begin
                valid = 1'b0;
                cancelled = 1'b0;
                done = 1'b0;
            end
            F_VALID: begin
                valid = 1'b1;
                cancelled = 1'b0;
                done = 1'b0;
            end
            F_CANCEL: begin
                valid = 1'b0;
                cancelled = 1'b1;
                done = 1'b0;
            end
            F_DONE: begin
                valid = 1'b0;
                cancelled = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
