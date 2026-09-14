module timer_0005_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  active,
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
            IDLE: next_state = (enable) ? RUN : (IDLE);
            RUN: next_state = (!enable) ? IDLE : (WARNING);
            WARNING: next_state = (!enable) ? IDLE : (TIMEOUT);
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
        active = (state == RUN) || (state == WARNING);
        warning = (state == WARNING);
        timeout = (state == TIMEOUT);
    end
endmodule
