`ifndef GOLD_MODULE
`define GOLD_MODULE missing_gold_module
`endif
`ifndef GATE_MODULE
`define GATE_MODULE missing_gate_module
`endif

module difference_harness;
    (* gclk *) reg formal_clock;
    reg clk = 1'b0;
    always @(posedge formal_clock)
        clk <= !clk;
    (* anyseq *) reg rst;
    (* anyseq *) reg req;
    (* anyseq *) reg ready;
    (* anyseq *) reg cancel;

    wire gold_busy, gold_ack;
    wire gate_busy, gate_ack;

    `GOLD_MODULE gold (
        .clk(clk), .rst(rst), .req(req), .ready(ready), .cancel(cancel),
        .busy(gold_busy), .ack(gold_ack)
    );

    `GATE_MODULE gate (
        .clk(clk), .rst(rst), .req(req), .ready(ready), .cancel(cancel),
        .busy(gate_busy), .ack(gate_ack)
    );

    reg f_past_valid = 1'b0;
    always @(posedge clk) begin
        if (!f_past_valid)
            assume(rst);
        if (f_past_valid)
            cover((gold_busy != gate_busy) || (gold_ack != gate_ack));
        f_past_valid <= 1'b1;
    end
endmodule
