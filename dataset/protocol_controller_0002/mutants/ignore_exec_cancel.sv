module protocol_controller_0002_mutant_ignore_exec_cancel (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire authorized,
    input  wire complete,
    input  wire cancel,
    output reg  authorizing,
    output reg  executing,
    output reg  done,
    output reg  cancelled
);
    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] AUTH  = 3'd1;
    localparam [2:0] EXEC  = 3'd2;
    localparam [2:0] DONE  = 3'd3;
    localparam [2:0] CANCEL = 3'd4;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (request) ? AUTH : ((!request) ? IDLE : (IDLE));
            AUTH: next_state = (cancel) ? CANCEL : ((!cancel && authorized) ? EXEC : ((!cancel && !authorized) ? AUTH : (AUTH)));
            EXEC: next_state = (!cancel && complete) ? DONE : ((!cancel && !complete) ? EXEC : (EXEC));
            DONE: next_state = IDLE;
            CANCEL: next_state = IDLE;
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
        authorizing = 1'b0;
        executing = 1'b0;
        done = 1'b0;
        cancelled = 1'b0;
        case (state)
            IDLE: begin
                authorizing = 1'b0;
                executing = 1'b0;
                done = 1'b0;
                cancelled = 1'b0;
            end
            AUTH: begin
                authorizing = 1'b1;
                executing = 1'b0;
                done = 1'b0;
                cancelled = 1'b0;
            end
            EXEC: begin
                authorizing = 1'b0;
                executing = 1'b1;
                done = 1'b0;
                cancelled = 1'b0;
            end
            DONE: begin
                authorizing = 1'b0;
                executing = 1'b0;
                done = 1'b1;
                cancelled = 1'b0;
            end
            CANCEL: begin
                authorizing = 1'b0;
                executing = 1'b0;
                done = 1'b0;
                cancelled = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
