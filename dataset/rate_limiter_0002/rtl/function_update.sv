module rate_limiter_0002_function_update (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire new_window,
    output wire [1:0] used,
    output wire epoch,
    output wire allow,
    output wire exhausted
);

    reg [1:0] used_reg;
    reg epoch_reg;

    function automatic [1:0] compute_next_used_reg;
        input [1:0] current_used_reg;
        input current_epoch_reg;
        input request;
        input new_window;
        begin
            if (new_window) compute_next_used_reg = 2'd0;
            else if (!new_window && request && (current_used_reg < 2'd3)) compute_next_used_reg = current_used_reg + 2'd1;
            else compute_next_used_reg = current_used_reg;
        end
    endfunction

    function automatic compute_next_epoch_reg;
        input [1:0] current_used_reg;
        input current_epoch_reg;
        input request;
        input new_window;
        begin
            if (new_window) compute_next_epoch_reg = !current_epoch_reg;
            else compute_next_epoch_reg = current_epoch_reg;
        end
    endfunction

    wire [1:0] next_used_reg;
    wire next_epoch_reg;

    assign next_used_reg = compute_next_used_reg(used_reg, epoch_reg, request, new_window);
    assign next_epoch_reg = compute_next_epoch_reg(used_reg, epoch_reg, request, new_window);

    always @(posedge clk) begin
        if (rst) begin
            used_reg <= 2'd0;
            epoch_reg <= 1'b0;
        end
        else begin
            used_reg <= next_used_reg;
            epoch_reg <= next_epoch_reg;
        end
    end

    assign used = used_reg;
    assign epoch = epoch_reg;
    assign allow = used_reg < 2'd3;
    assign exhausted = used_reg == 2'd3;
endmodule
