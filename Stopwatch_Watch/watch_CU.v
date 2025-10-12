`timescale 1ns / 1ps

module watch_CU (
    input       clk,
    input       rst,
    input       btn_shift_left,
    input       btn_shift_right,
    input       sw0,
    input [7:0] uart_rx,
    input       uart_rx_done,

    output [1:0] o_field_sel  // 00: msec, 01: sec, 10: min, 11: hour
);

    reg [1:0] c_state, n_state;

    parameter MSEC = 2'b00;
    parameter SEC = 2'b01;
    parameter MIN = 2'b10;
    parameter HOUR = 2'b11;


    always @(posedge clk, posedge rst) begin
        if (rst) c_state <= MSEC;
        else c_state <= n_state;
    end

    always @(*) begin
        n_state = c_state;
        case (c_state)
            MSEC: begin
                if (sw0) n_state = MIN;
                else if (btn_shift_left) n_state = SEC;
                else if (uart_rx_done) begin
                    if ((uart_rx == 8'h4e) | (uart_rx == 8'h6e)) begin
                        n_state = MIN;
                    end else if ((uart_rx == 8'h4c) | (uart_rx == 8'h6c)) begin
                        n_state = SEC;
                    end
                end else n_state = c_state;
            end
            SEC: begin
                if (sw0) n_state = HOUR;
                else if (btn_shift_right) n_state = MSEC;
                else if (uart_rx_done) begin
                    if ((uart_rx == 8'h4e) | (uart_rx == 8'h6e)) begin
                        n_state = HOUR;
                    end else if ((uart_rx == 8'h52) | (uart_rx == 8'h72)) begin
                        n_state = MSEC;
                    end
                end else n_state = c_state;
            end
            MIN: begin
                if (sw0 == 0) n_state = MSEC;
                else if (btn_shift_left) n_state = HOUR;
                else if (uart_rx_done) begin
                    if ((uart_rx == 8'h4e) | (uart_rx == 8'h6e)) begin
                        n_state = MSEC;
                    end else if ((uart_rx == 8'h4c) | (uart_rx == 8'h6c)) begin
                        n_state = HOUR;
                    end
                end else n_state = c_state;
            end
            HOUR: begin
                if (sw0 == 0) n_state = SEC;
                else if (btn_shift_right) n_state = MIN;
                else if (uart_rx_done) begin
                    if ((uart_rx == 8'h4e) | (uart_rx == 8'h6e)) begin
                        n_state = SEC;
                    end else if ((uart_rx == 8'h52) | (uart_rx == 8'h72)) begin
                        n_state = MIN;
                    end
                end else n_state = c_state;
            end
        endcase
    end

    assign o_field_sel = c_state;


endmodule

