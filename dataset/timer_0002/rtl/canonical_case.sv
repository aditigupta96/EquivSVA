module timer_0002_canonical_case (
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
    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] EARLY = 3'd1;
    localparam [2:0] WINDOW = 3'd2;
    localparam [2:0] SERVICED = 3'd3;
    localparam [2:0] EARLY_FAULT = 3'd4;
    localparam [2:0] TIMEOUT = 3'd5;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (start) ? EARLY : (IDLE);
            EARLY: next_state = (service) ? EARLY_FAULT : (WINDOW);
            WINDOW: next_state = (service) ? SERVICED : (TIMEOUT);
            SERVICED: next_state = IDLE;
            EARLY_FAULT: next_state = IDLE;
            TIMEOUT: next_state = IDLE;
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
        active = 1'b0;
        window_open = 1'b0;
        serviced = 1'b0;
        early_fault = 1'b0;
        timeout = 1'b0;
        case (state)
            IDLE: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            EARLY: begin
                active = 1'b1;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            WINDOW: begin
                active = 1'b1;
                window_open = 1'b1;
                serviced = 1'b0;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            SERVICED: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b1;
                early_fault = 1'b0;
                timeout = 1'b0;
            end
            EARLY_FAULT: begin
                active = 1'b0;
                window_open = 1'b0;
                serviced = 1'b0;
                early_fault = 1'b1;
                timeout = 1'b0;
            end
            TIMEOUT: begin
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
