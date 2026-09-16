module protocol_controller_0010_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire quiesce,
    input  wire idle_seen,
    output reg  running,
    output reg  draining,
    output reg  stopped
);
    localparam [2:0] STOP  = 3'b001;
    localparam [2:0] RUN   = 3'b010;
    localparam [2:0] DRAIN = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = STOP;
        case (state)
            STOP: next_state = (enable) ? RUN : ((!enable) ? STOP : (STOP));
            RUN: next_state = (quiesce) ? DRAIN : ((!quiesce) ? RUN : (RUN));
            DRAIN: next_state = (idle_seen) ? STOP : ((!idle_seen) ? DRAIN : (DRAIN));
            default: next_state = STOP;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= STOP;
        else
            state <= next_state;
    end

    always @* begin
        running = (state == RUN);
        draining = (state == DRAIN);
        stopped = (state == STOP);
    end
endmodule
