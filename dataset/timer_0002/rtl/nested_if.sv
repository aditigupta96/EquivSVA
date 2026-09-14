module timer_0002_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire service,
    output wire active,
    output wire window_open,
    output wire serviced,
    output wire early_fault,
    output wire timeout
);
    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_EARLY  = 3'd1;
    localparam [2:0] S_WINDOW = 3'd2;
    localparam [2:0] S_SERVICED = 3'd3;
    localparam [2:0] S_EARLY_FAULT = 3'd4;
    localparam [2:0] S_TIMEOUT = 3'd5;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_EARLY : (S_IDLE);
            end
            else if (state == S_EARLY) begin
                state <= (service) ? S_EARLY_FAULT : (S_WINDOW);
            end
            else if (state == S_WINDOW) begin
                state <= (service) ? S_SERVICED : (S_TIMEOUT);
            end
            else if (state == S_SERVICED) begin
                state <= S_IDLE;
            end
            else if (state == S_EARLY_FAULT) begin
                state <= S_IDLE;
            end
            else if (state == S_TIMEOUT) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign active = (state == S_EARLY) || (state == S_WINDOW);
    assign window_open = (state == S_WINDOW);
    assign serviced = (state == S_SERVICED);
    assign early_fault = (state == S_EARLY_FAULT);
    assign timeout = (state == S_TIMEOUT);
endmodule
