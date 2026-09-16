module mode_controller_0008_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire boot_ok,
    input  wire start,
    input  wire stop,
    output reg  booting,
    output reg  ready,
    output reg  running
);
    localparam [2:0] BOOT  = 3'b001;
    localparam [2:0] READY = 3'b010;
    localparam [2:0] RUN   = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = BOOT;
        case (state)
            BOOT: next_state = (boot_ok) ? READY : ((!boot_ok) ? BOOT : (BOOT));
            READY: next_state = (start) ? RUN : ((!start) ? READY : (READY));
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
        booting = (state == BOOT);
        ready = (state == READY);
        running = (state == RUN);
    end
endmodule
