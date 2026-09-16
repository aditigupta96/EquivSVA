module mode_controller_0004_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire fault,
    input  wire clear,
    output reg  running,
    output reg  safe,
    output reg  faulted
);
    localparam [1:0] F_SAFE         = 2'd0;
    localparam [1:0] F_RUN          = 2'd1;
    localparam [1:0] F_FAULT        = 2'd2;

    reg [1:0] state, next_state;

    wire guard_safe_0 = (start);
    wire guard_safe_1 = (!start);
    wire guard_run_0 = (fault);
    wire guard_run_1 = (!fault);
    wire guard_fault_0 = (clear);
    wire guard_fault_1 = (!clear);

    always @* begin
        next_state = state;
        case (state)
            F_SAFE: begin
                if (guard_safe_0)
                    next_state = F_RUN;
                else if (guard_safe_1)
                    next_state = F_SAFE;
            end
            F_RUN: begin
                if (guard_run_0)
                    next_state = F_FAULT;
                else if (guard_run_1)
                    next_state = F_RUN;
            end
            F_FAULT: begin
                if (guard_fault_0)
                    next_state = F_SAFE;
                else if (guard_fault_1)
                    next_state = F_FAULT;
            end
            default: next_state = F_SAFE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_SAFE;
        else
            state <= next_state;
    end

    always @* begin
        running = 1'b0;
        safe = 1'b0;
        faulted = 1'b0;
        case (state)
            F_SAFE: begin
                running = 1'b0;
                safe = 1'b1;
                faulted = 1'b0;
            end
            F_RUN: begin
                running = 1'b1;
                safe = 1'b0;
                faulted = 1'b0;
            end
            F_FAULT: begin
                running = 1'b0;
                safe = 1'b0;
                faulted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
