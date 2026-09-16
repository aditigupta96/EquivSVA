module rate_limiter_0007_function_update (
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

    function automatic [1:0] compute_next_used_reg;
        input [1:0] current_used_reg;
        input [1:0] current_phase_reg;
        input request;
        input advance_window;
        begin
            if (advance_window) compute_next_used_reg = 2'd0;
            else if (!advance_window && request && (current_used_reg < 2'd3)) compute_next_used_reg = current_used_reg + 2'd1;
            else compute_next_used_reg = current_used_reg;
        end
    endfunction

    function automatic [1:0] compute_next_phase_reg;
        input [1:0] current_used_reg;
        input [1:0] current_phase_reg;
        input request;
        input advance_window;
        begin
            if (advance_window && (current_phase_reg < 2'd3)) compute_next_phase_reg = current_phase_reg + 2'd1;
            else if (advance_window && (current_phase_reg == 2'd3)) compute_next_phase_reg = 2'd0;
            else compute_next_phase_reg = current_phase_reg;
        end
    endfunction

    wire [1:0] next_used_reg;
    wire [1:0] next_phase_reg;

    assign next_used_reg = compute_next_used_reg(used_reg, phase_reg, request, advance_window);
    assign next_phase_reg = compute_next_phase_reg(used_reg, phase_reg, request, advance_window);

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
