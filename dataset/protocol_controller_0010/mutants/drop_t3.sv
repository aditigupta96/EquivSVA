module protocol_controller_0010_mutant_drop_t3 (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire quiesce,
    input  wire idle_seen,
    output reg  running,
    output reg  draining,
    output reg  stopped
);
    localparam [1:0] STOP  = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] DRAIN = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            STOP: next_state = (enable) ? RUN : ((!enable) ? STOP : (STOP));
            RUN: next_state = (!quiesce) ? RUN : (RUN);
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
        running = 1'b0;
        draining = 1'b0;
        stopped = 1'b0;
        case (state)
            STOP: begin
                running = 1'b0;
                draining = 1'b0;
                stopped = 1'b1;
            end
            RUN: begin
                running = 1'b1;
                draining = 1'b0;
                stopped = 1'b0;
            end
            DRAIN: begin
                running = 1'b0;
                draining = 1'b1;
                stopped = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule
