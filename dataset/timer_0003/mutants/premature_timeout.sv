module timer_0003_mutant_premature_timeout (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire cancel,
    output reg  active,
    output reg  warning,
    output reg  timeout
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] WARNING = 2'd2;
    localparam [1:0] TIMEOUT = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (start) ? RUN : (IDLE);
            RUN: next_state = TIMEOUT;
            WARNING: next_state = (cancel) ? IDLE : (TIMEOUT);
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
        warning = 1'b0;
        timeout = 1'b0;
        case (state)
            IDLE: begin
                active = 1'b0;
                warning = 1'b0;
                timeout = 1'b0;
            end
            RUN: begin
                active = 1'b1;
                warning = 1'b0;
                timeout = 1'b0;
            end
            WARNING: begin
                active = 1'b1;
                warning = 1'b1;
                timeout = 1'b0;
            end
            TIMEOUT: begin
                active = 1'b0;
                warning = 1'b0;
                timeout = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
