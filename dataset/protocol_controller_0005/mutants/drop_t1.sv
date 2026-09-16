module protocol_controller_0005_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire prepare_ok,
    input  wire commit_ok,
    output reg  preparing,
    output reg  committing,
    output reg  done
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] PREP  = 2'd1;
    localparam [1:0] COMMIT = 2'd2;
    localparam [1:0] DONE  = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (!start) ? IDLE : (IDLE);
            PREP: next_state = (prepare_ok) ? COMMIT : ((!prepare_ok) ? PREP : (PREP));
            COMMIT: next_state = (commit_ok) ? DONE : ((!commit_ok) ? COMMIT : (COMMIT));
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
        preparing = 1'b0;
        committing = 1'b0;
        done = 1'b0;
        case (state)
            IDLE: begin
                preparing = 1'b0;
                committing = 1'b0;
                done = 1'b0;
            end
            PREP: begin
                preparing = 1'b1;
                committing = 1'b0;
                done = 1'b0;
            end
            COMMIT: begin
                preparing = 1'b0;
                committing = 1'b1;
                done = 1'b0;
            end
            DONE: begin
                preparing = 1'b0;
                committing = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
