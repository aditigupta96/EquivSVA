module timer_0002_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire service,
    output reg  active,
    output reg  window_open,
    output reg  serviced,
    output reg  early_fault,
    output reg  timeout
);
    localparam [2:0] F_IDLE         = 3'd0;
    localparam [2:0] F_EARLY        = 3'd1;
    localparam [2:0] F_WINDOW       = 3'd2;
    localparam [2:0] F_SERVICED     = 3'd3;
    localparam [2:0] F_EARLY_FAULT  = 3'd4;
    localparam [2:0] F_TIMEOUT      = 3'd5;

    reg [2:0] state, next_state;

    wire guard_idle_0 = (start);
    wire guard_early_0 = (service);
    wire guard_window_0 = (service);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_EARLY;
                else
                    next_state = F_IDLE;
            end
            F_EARLY: begin
                if (guard_early_0)
                    next_state = F_EARLY_FAULT;
                else
                    next_state = F_WINDOW;
            end
            F_WINDOW: begin
                if (guard_window_0)
                    next_state = F_SERVICED;
                else
                    next_state = F_TIMEOUT;
            end
            F_SERVICED: begin
                next_state = F_IDLE;
            end
            F_EARLY_FAULT: begin
                next_state = F_IDLE;
            end
            F_TIMEOUT: begin
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
        active = 1'b0;
        window_open = 1'b0;
        serviced = 1'b0;
        early_fault = 1'b0;
        timeout = 1'b0;
        case (state)
            F_IDLE: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            F_EARLY: begin
                active = 1'b1;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            F_WINDOW: begin
                active = 1'b1;
                window_open = 1'b1;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            F_SERVICED: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b1;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            F_EARLY_FAULT: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b1;
                timeout = 1'b0;
            end
            F_TIMEOUT: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
