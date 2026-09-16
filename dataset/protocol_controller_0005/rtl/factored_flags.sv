module protocol_controller_0005_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire prepare_ok,
    input  wire commit_ok,
    output reg  preparing,
    output reg  committing,
    output reg  done
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_PREP         = 2'd1;
    localparam [1:0] F_COMMIT       = 2'd2;
    localparam [1:0] F_DONE         = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_idle_1 = (!start);
    wire guard_prep_0 = (prepare_ok);
    wire guard_prep_1 = (!prepare_ok);
    wire guard_commit_0 = (commit_ok);
    wire guard_commit_1 = (!commit_ok);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_PREP;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_PREP: begin
                if (guard_prep_0)
                    next_state = F_COMMIT;
                else if (guard_prep_1)
                    next_state = F_PREP;
            end
            F_COMMIT: begin
                if (guard_commit_0)
                    next_state = F_DONE;
                else if (guard_commit_1)
                    next_state = F_COMMIT;
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
        preparing = 1'b0;
        committing = 1'b0;
        done = 1'b0;
        case (state)
            F_IDLE: begin
                preparing = 1'b0;
                committing = 1'b0;
                done = 1'b0;
            end
            F_PREP: begin
                preparing = 1'b1;
                committing = 1'b0;
                done = 1'b0;
            end
            F_COMMIT: begin
                preparing = 1'b0;
                committing = 1'b1;
                done = 1'b0;
            end
            F_DONE: begin
                preparing = 1'b0;
                committing = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
