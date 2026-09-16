module rate_limiter_0007_mutant_never_reset_quota (
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

    always @(posedge clk) begin
        if (rst) begin
            used_reg <= 2'd0;
            phase_reg <= 2'd0;
        end
        else begin
            if (!advance_window && request && (used_reg < 2'd3)) used_reg <= used_reg + 2'd1;
            else used_reg <= used_reg;
            if (advance_window && (phase_reg < 2'd3)) phase_reg <= phase_reg + 2'd1;
            else if (advance_window && (phase_reg == 2'd3)) phase_reg <= 2'd0;
            else phase_reg <= phase_reg;
        end
    end

    assign used = used_reg;
    assign phase = phase_reg;
    assign allow = used_reg < 2'd3;
    assign exhausted = used_reg == 2'd3;
endmodule
