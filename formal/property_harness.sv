`ifndef DUT_MODULE
`define DUT_MODULE missing_dut_module
`endif

module property_harness;
    (* gclk *) reg formal_clock;
    reg clk = 1'b0;
    always @(posedge formal_clock)
        clk <= !clk;
    (* anyseq *) reg rst;
    (* anyseq *) reg req;
    (* anyseq *) reg ready;
    (* anyseq *) reg cancel;

    wire busy;
    wire ack;

    `DUT_MODULE dut (
        .clk(clk), .rst(rst), .req(req), .ready(ready), .cancel(cancel), .busy(busy), .ack(ack)
    );

    reg f_past_valid = 1'b0;

    always @(posedge clk) begin
        if (!f_past_valid)
            assume(rst);

        if (f_past_valid) begin
            if (!rst) assert(!(busy && ack)); // P1_MUTEX
            if (($past(rst))) assert(!busy && !ack); // P2_RESET_IDLE
            if (!$past(rst) && !rst && ((!$past(busy) && !$past(ack)) && $past(req) && $past(ready))) assert(busy); // P3_ACCEPT_TO_BUSY
            if (!$past(rst) && !rst && ((!$past(busy) && !$past(ack)) && !($past(req) && $past(ready)))) assert(!busy && !ack); // P4_IDLE_STAYS_IDLE
            if (!$past(rst) && !rst && ($past(busy) && $past(cancel))) assert(!busy && !ack); // P5_CANCEL_TO_IDLE
            if (!$past(rst) && !rst && ($past(busy) && !$past(cancel))) assert(ack); // P6_BUSY_TO_ACK
            if (!$past(rst) && !rst && ($past(ack))) assert(!busy && !ack); // P7_ACK_TO_IDLE
        end

        f_past_valid <= 1'b1;
    end

    // Reachability/non-vacuity witnesses.
    always @(posedge clk) begin
        if (f_past_valid) begin
            cover(rst); // P2_RESET_IDLE
            cover(!rst && ((!busy && !ack) && req && ready)); // P3_ACCEPT_TO_BUSY
            cover(!rst && ((!busy && !ack) && !(req && ready))); // P4_IDLE_STAYS_IDLE
            cover(!rst && (busy && cancel)); // P5_CANCEL_TO_IDLE
            cover(!rst && (busy && !cancel)); // P6_BUSY_TO_ACK
            cover(!rst && (ack)); // P7_ACK_TO_IDLE
        end
    end
endmodule
