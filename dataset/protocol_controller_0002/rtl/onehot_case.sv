module protocol_controller_0002_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire authorized,
    input  wire complete,
    input  wire cancel,
    output reg  authorizing,
    output reg  executing,
    output reg  done,
    output reg  cancelled
);
    localparam [4:0] IDLE  = 5'b00001;
    localparam [4:0] AUTH  = 5'b00010;
    localparam [4:0] EXEC  = 5'b00100;
    localparam [4:0] DONE  = 5'b01000;
    localparam [4:0] CANCEL = 5'b10000;

    reg [4:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (request) ? AUTH : ((!request) ? IDLE : (IDLE));
            AUTH: next_state = (cancel) ? CANCEL : ((!cancel && authorized) ? EXEC : ((!cancel && !authorized) ? AUTH : (AUTH)));
            EXEC: next_state = (cancel) ? CANCEL : ((!cancel && complete) ? DONE : ((!cancel && !complete) ? EXEC : (EXEC)));
            DONE: next_state = IDLE;
            CANCEL: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        authorizing = (state == AUTH);
        executing = (state == EXEC);
        done = (state == DONE);
        cancelled = (state == CANCEL);
    end
endmodule
