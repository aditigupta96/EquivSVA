module timer_0001_mutant_ignore_kick (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire kick,
    output reg  running,
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
            RUN: next_state = WARNING;
            WARNING: next_state = (kick) ? RUN : (TIMEOUT);
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
        running = 1'b0;
        warning = 1'b0;
        timeout = 1'b0;
        case (state)
            IDLE: begin
                running = 1'b0;
                warning = 1'b0;
                timeout = 1'b0;
            end
            RUN: begin
                running = 1'b1;
                warning = 1'b0;
                timeout = 1'b0;
            end
            WARNING: begin
                running = 1'b1;
                warning = 1'b1;
                timeout = 1'b0;
            end
            TIMEOUT: begin
                running = 1'b0;
                warning = 1'b0;
                timeout = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
