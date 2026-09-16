module rate_limiter_0002_sequential_priority (
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

    always @(posedge clk) begin
        if (rst) begin
            used_reg <= 2'd0;
            epoch_reg <= 1'b0;
        end
        else begin
            if (new_window) used_reg <= 2'd0;
            else if (!new_window && request && (used_reg < 2'd3)) used_reg <= used_reg + 2'd1;
            else used_reg <= used_reg;
            if (new_window) epoch_reg <= !epoch_reg;
            else epoch_reg <= epoch_reg;
        end
    end

    assign used = used_reg;
    assign epoch = epoch_reg;
    assign allow = used_reg < 2'd3;
    assign exhausted = used_reg == 2'd3;
endmodule
