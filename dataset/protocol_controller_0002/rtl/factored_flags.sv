module protocol_controller_0002_factored_flags (
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
    localparam [2:0] F_IDLE         = 3'd0;
    localparam [2:0] F_AUTH         = 3'd1;
    localparam [2:0] F_EXEC         = 3'd2;
    localparam [2:0] F_DONE         = 3'd3;
    localparam [2:0] F_CANCEL       = 3'd4;

    reg [2:0] state, next_state;

    wire guard_idle_0 = (request);
    wire guard_idle_1 = (!request);
    wire guard_auth_0 = (cancel);
    wire guard_auth_1 = (!cancel && authorized);
    wire guard_auth_2 = (!cancel && !authorized);
    wire guard_exec_0 = (cancel);
    wire guard_exec_1 = (!cancel && complete);
    wire guard_exec_2 = (!cancel && !complete);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_AUTH;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_AUTH: begin
                if (guard_auth_0)
                    next_state = F_CANCEL;
                else if (guard_auth_1)
                    next_state = F_EXEC;
                else if (guard_auth_2)
                    next_state = F_AUTH;
            end
            F_EXEC: begin
                if (guard_exec_0)
                    next_state = F_CANCEL;
                else if (guard_exec_1)
                    next_state = F_DONE;
                else if (guard_exec_2)
                    next_state = F_EXEC;
            end
            F_DONE: begin
                next_state = F_IDLE;
            end
            F_CANCEL: begin
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
        authorizing = 1'b0;
        executing = 1'b0;
        done = 1'b0;
        cancelled = 1'b0;
        case (state)
            F_IDLE: begin
                authorizing = 1'b0;
                executing = 1'b0;
                done = 1'b0;
                cancelled = 1'b0;
            end
            F_AUTH: begin
                authorizing = 1'b1;
                executing = 1'b0;
                done = 1'b0;
                cancelled = 1'b0;
            end
            F_EXEC: begin
                authorizing = 1'b0;
                executing = 1'b1;
                done = 1'b0;
                cancelled = 1'b0;
            end
            F_DONE: begin
                authorizing = 1'b0;
                executing = 1'b0;
                done = 1'b1;
                cancelled = 1'b0;
            end
            F_CANCEL: begin
                authorizing = 1'b0;
                executing = 1'b0;
                done = 1'b0;
                cancelled = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
