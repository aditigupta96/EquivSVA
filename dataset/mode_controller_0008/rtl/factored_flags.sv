module mode_controller_0008_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire boot_ok,
    input  wire start,
    input  wire stop,
    output reg  booting,
    output reg  ready,
    output reg  running
);
    localparam [1:0] F_BOOT         = 2'd0;
    localparam [1:0] F_READY        = 2'd1;
    localparam [1:0] F_RUN          = 2'd2;

    reg [1:0] state, next_state;

    wire guard_boot_0 = (boot_ok);
    wire guard_boot_1 = (!boot_ok);
    wire guard_ready_0 = (start);
    wire guard_ready_1 = (!start);
    wire guard_run_0 = (stop);
    wire guard_run_1 = (!stop);

    always @* begin
        next_state = state;
        case (state)
            F_BOOT: begin
                if (guard_boot_0)
                    next_state = F_READY;
                else if (guard_boot_1)
                    next_state = F_BOOT;
            end
            F_READY: begin
                if (guard_ready_0)
                    next_state = F_RUN;
                else if (guard_ready_1)
                    next_state = F_READY;
            end
            F_RUN: begin
                if (guard_run_0)
                    next_state = F_READY;
                else if (guard_run_1)
                    next_state = F_RUN;
            end
            default: next_state = F_BOOT;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_BOOT;
        else
            state <= next_state;
    end

    always @* begin
        booting = 1'b0;
        ready = 1'b0;
        running = 1'b0;
        case (state)
            F_BOOT: begin
                booting = 1'b1;
                ready = 1'b0;
                running = 1'b0;
            end
            F_READY: begin
                booting = 1'b0;
                ready = 1'b1;
                running = 1'b0;
            end
            F_RUN: begin
                booting = 1'b0;
                ready = 1'b0;
                running = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
