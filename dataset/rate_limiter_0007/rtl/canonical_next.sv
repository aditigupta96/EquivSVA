module rate_limiter_0007_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire advance_window,
    output wire [1:0] used,
    output wire [1:0] phase,
    output wire allow,
    output wire exhausted
);

    reg [1:0] used_reg;
    reg [1:0] phase_reg;

    reg [1:0] next_used_reg;
    reg [1:0] next_phase_reg;

    always @* begin
        if (advance_window) next_used_reg = 2'd0;
        else if (!advance_window && request && (used_reg < 2'd3)) next_used_reg = used_reg + 2'd1;
        else next_used_reg = used_reg;
        if (advance_window && (phase_reg < 2'd3)) next_phase_reg = phase_reg + 2'd1;
        else if (advance_window && (phase_reg == 2'd3)) next_phase_reg = 2'd0;
        else next_phase_reg = phase_reg;
    end

    always @(posedge clk) begin
        if (rst) begin
            used_reg <= 2'd0;
            phase_reg <= 2'd0;
        end
        else begin
            used_reg <= next_used_reg;
            phase_reg <= next_phase_reg;
        end
    end

    assign used = used_reg;
    assign phase = phase_reg;
    assign allow = used_reg < 2'd3;
    assign exhausted = used_reg == 2'd3;
endmodule
