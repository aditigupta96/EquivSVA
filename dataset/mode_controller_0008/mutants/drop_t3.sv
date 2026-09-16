module mode_controller_0008_mutant_drop_t3 (
    input  wire clk,
    input  wire rst,
    input  wire boot_ok,
    input  wire start,
    input  wire stop,
    output reg  booting,
    output reg  ready,
    output reg  running
);
    localparam [1:0] BOOT  = 2'd0;
    localparam [1:0] READY = 2'd1;
    localparam [1:0] RUN   = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            BOOT: next_state = (boot_ok) ? READY : ((!boot_ok) ? BOOT : (BOOT));
            READY: next_state = (!start) ? READY : (READY);
            RUN: next_state = (stop) ? READY : ((!stop) ? RUN : (RUN));
            default: next_state = BOOT;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= BOOT;
        else
            state <= next_state;
    end

    always @* begin
        booting = 1'b0;
        ready = 1'b0;
        running = 1'b0;
        case (state)
            BOOT: begin
                booting = 1'b1;
                ready = 1'b0;
                running = 1'b0;
            end
            READY: begin
                booting = 1'b0;
                ready = 1'b1;
                running = 1'b0;
            end
            RUN: begin
                booting = 1'b0;
                ready = 1'b0;
                running = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule
