module protocol_controller_0001_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire ack,
    input  wire abort,
    output reg  busy,
    output reg  done,
    output reg  error
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] WAIT_ACK = 4'b0010;
    localparam [3:0] DONE  = 4'b0100;
    localparam [3:0] ERROR = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? WAIT_ACK : ((!start) ? IDLE : (IDLE));
            WAIT_ACK: next_state = (abort) ? ERROR : ((!abort && ack) ? DONE : ((!abort && !ack) ? WAIT_ACK : (WAIT_ACK)));
            DONE: next_state = IDLE;
            ERROR: next_state = IDLE;
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
        busy = (state == WAIT_ACK);
        done = (state == DONE);
        error = (state == ERROR);
    end
endmodule
