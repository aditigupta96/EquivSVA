module protocol_controller_0003_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire prepared,
    input  wire commit,
    input  wire abort,
    input  wire recover,
    output reg  preparing,
    output reg  ready_commit,
    output reg  committed,
    output reg  aborted
);
    localparam [2:0] F_IDLE         = 3'd0;
    localparam [2:0] F_PREPARE      = 3'd1;
    localparam [2:0] F_READY        = 3'd2;
    localparam [2:0] F_COMMITTED    = 3'd3;
    localparam [2:0] F_ABORTED      = 3'd4;

    reg [2:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_idle_1 = (!start);
    wire guard_prepare_0 = (abort);
    wire guard_prepare_1 = (!abort && prepared);
    wire guard_prepare_2 = (!abort && !prepared);
    wire guard_ready_0 = (abort);
    wire guard_ready_1 = (!abort && commit);
    wire guard_ready_2 = (!abort && !commit);
    wire guard_aborted_0 = (recover);
    wire guard_aborted_1 = (!recover);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_PREPARE;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_PREPARE: begin
                if (guard_prepare_0)
                    next_state = F_ABORTED;
                else if (guard_prepare_1)
                    next_state = F_READY;
                else if (guard_prepare_2)
                    next_state = F_PREPARE;
            end
            F_READY: begin
                if (guard_ready_0)
                    next_state = F_ABORTED;
                else if (guard_ready_1)
                    next_state = F_COMMITTED;
                else if (guard_ready_2)
                    next_state = F_READY;
            end
            F_COMMITTED: begin
                next_state = F_IDLE;
            end
            F_ABORTED: begin
                if (guard_aborted_0)
                    next_state = F_IDLE;
                else if (guard_aborted_1)
                    next_state = F_ABORTED;
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
        ready_commit = 1'b0;
        committed = 1'b0;
        aborted = 1'b0;
        case (state)
            F_IDLE: begin
                preparing = 1'b0;
                ready_commit = 1'b0;
                committed = 1'b0;
                aborted = 1'b0;
            end
            F_PREPARE: begin
                preparing = 1'b1;
                ready_commit = 1'b0;
                committed = 1'b0;
                aborted = 1'b0;
            end
            F_READY: begin
                preparing = 1'b0;
                ready_commit = 1'b1;
                committed = 1'b0;
                aborted = 1'b0;
            end
            F_COMMITTED: begin
                preparing = 1'b0;
                ready_commit = 1'b0;
                committed = 1'b1;
                aborted = 1'b0;
            end
            F_ABORTED: begin
                preparing = 1'b0;
                ready_commit = 1'b0;
                committed = 1'b0;
                aborted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
