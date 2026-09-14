module timer_0001_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire kick,
    output reg  running,
    output reg  warning,
    output reg  timeout
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] RUN   = 4'b0010;
    localparam [3:0] WARNING = 4'b0100;
    localparam [3:0] TIMEOUT = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? RUN : (IDLE);
            RUN: next_state = (kick) ? RUN : (WARNING);
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
        running = (state == RUN) || (state == WARNING);
        warning = (state == WARNING);
        timeout = (state == TIMEOUT);
    end
endmodule
