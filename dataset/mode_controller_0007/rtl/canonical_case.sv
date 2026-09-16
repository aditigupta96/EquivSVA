module mode_controller_0007_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire run,
    input  wire fault,
    input  wire clear,
    output reg  standby,
    output reg  running,
    output reg  faulted
);
    localparam [1:0] STANDBY = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] FAULT = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            STANDBY: next_state = (run) ? RUN : ((!run) ? STANDBY : (STANDBY));
            RUN: next_state = (fault) ? FAULT : ((!fault && run) ? RUN : ((!fault && !run) ? STANDBY : (RUN)));
            FAULT: next_state = (clear) ? STANDBY : ((!clear) ? FAULT : (FAULT));
            default: next_state = STANDBY;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= STANDBY;
        else
            state <= next_state;
    end

    always @* begin
        standby = 1'b0;
        running = 1'b0;
        faulted = 1'b0;
        case (state)
            STANDBY: begin
                standby = 1'b1;
                running = 1'b0;
                faulted = 1'b0;
            end
            RUN: begin
                standby = 1'b0;
                running = 1'b1;
                faulted = 1'b0;
            end
            FAULT: begin
                standby = 1'b0;
                running = 1'b0;
                faulted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
