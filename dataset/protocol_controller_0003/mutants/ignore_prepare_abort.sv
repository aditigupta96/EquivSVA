module protocol_controller_0003_mutant_ignore_prepare_abort (
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
    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] PREPARE = 3'd1;
    localparam [2:0] READY = 3'd2;
    localparam [2:0] COMMITTED = 3'd3;
    localparam [2:0] ABORTED = 3'd4;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (start) ? PREPARE : ((!start) ? IDLE : (IDLE));
            PREPARE: next_state = (!abort && prepared) ? READY : ((!abort && !prepared) ? PREPARE : (PREPARE));
            READY: next_state = (abort) ? ABORTED : ((!abort && commit) ? COMMITTED : ((!abort && !commit) ? READY : (READY)));
            COMMITTED: next_state = IDLE;
            ABORTED: next_state = (recover) ? IDLE : ((!recover) ? ABORTED : (ABORTED));
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
        preparing = 1'b0;
        ready_commit = 1'b0;
        committed = 1'b0;
        aborted = 1'b0;
        case (state)
            IDLE: begin
                preparing = 1'b0;
                ready_commit = 1'b0;
                committed = 1'b0;
                aborted = 1'b0;
            end
            PREPARE: begin
                preparing = 1'b1;
                ready_commit = 1'b0;
                committed = 1'b0;
                aborted = 1'b0;
            end
            READY: begin
                preparing = 1'b0;
                ready_commit = 1'b1;
                committed = 1'b0;
                aborted = 1'b0;
            end
            COMMITTED: begin
                preparing = 1'b0;
                ready_commit = 1'b0;
                committed = 1'b1;
                aborted = 1'b0;
            end
            ABORTED: begin
                preparing = 1'b0;
                ready_commit = 1'b0;
                committed = 1'b0;
                aborted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
