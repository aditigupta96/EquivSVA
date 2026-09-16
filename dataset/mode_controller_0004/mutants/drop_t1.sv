module mode_controller_0004_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire fault,
    input  wire clear,
    output reg  running,
    output reg  safe,
    output reg  faulted
);
    localparam [1:0] SAFE  = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] FAULT = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            SAFE: next_state = (!start) ? SAFE : (SAFE);
            RUN: next_state = (fault) ? FAULT : ((!fault) ? RUN : (RUN));
            FAULT: next_state = (clear) ? SAFE : ((!clear) ? FAULT : (FAULT));
            default: next_state = SAFE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= SAFE;
        else
            state <= next_state;
    end

    always @* begin
        running = 1'b0;
        safe = 1'b0;
        faulted = 1'b0;
        case (state)
            SAFE: begin
                running = 1'b0;
                safe = 1'b1;
                faulted = 1'b0;
            end
            RUN: begin
                running = 1'b1;
                safe = 1'b0;
                faulted = 1'b0;
            end
            FAULT: begin
                running = 1'b0;
                safe = 1'b0;
                faulted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
