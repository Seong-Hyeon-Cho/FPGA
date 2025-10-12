`timescale 1ns / 1ps

module stopwatch_cu (
    input clk,
    input rst,
    input i_clear,
    input i_runstop,
    input [7:0] uart_rx,
    input uart_rx_done,
    output o_clear,
    output o_runstop
);
    reg [1:0] c_state, n_state;

    localparam G = 8'h47, g = 8'h67, S = 8'h53, s = 8'h73, C = 8'h43, c = 8'h63;
    parameter CLEAR = 2'b10;
    parameter RUN = 2'b01;
    parameter STOP = 2'b00;


    assign o_clear   = (c_state == CLEAR) ? 1 : 0;
    assign o_runstop = (c_state == RUN) ? 1 : 0;


    always @(posedge clk, posedge rst) begin
        if (rst) c_state <= STOP;
        else c_state <= n_state;
    end

    always @(*) begin
        n_state = c_state;
        case (c_state)
            CLEAR: begin
                if (i_runstop) n_state = RUN;
                else if (uart_rx_done) begin
                    if ((uart_rx == G) || (uart_rx == g)) begin
                        n_state = RUN;
                    end
                end else n_state = c_state;
            end

            STOP: begin
                if (i_runstop) n_state = RUN;
                else if (i_clear) n_state = CLEAR;
                else if (uart_rx_done) begin
                    if ((uart_rx == G) || (uart_rx == g)) begin
                        n_state = RUN;
                    end else if ((uart_rx == C) || (uart_rx == c)) begin
                        n_state = CLEAR;
                    end
                end else n_state = c_state;
            end

            RUN: begin
                if (i_runstop) n_state = STOP;
                else if (uart_rx_done) begin
                    if ((uart_rx == S) || (uart_rx == s)) begin
                        n_state = STOP;
                    end
                end else n_state = c_state;
            end
        endcase

    end
endmodule
