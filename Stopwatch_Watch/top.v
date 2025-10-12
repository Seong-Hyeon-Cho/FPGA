`timescale 1ns / 1ps


module top (
    input        clk,
    input        rst,
    input        uart_rx,
    input  [1:0] sw,
    input        btnU,
    input        btnD,
    input        btnL,
    input        btnR,
    output       tx,
    output [3:0] led,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);

    wire w_rx_done, w_rst;
    wire [7:0] w_uart_rx;

    Uart_controller U_Uart_CNTR (
        .clk    (clk),
        .rst    (rst),
        .rx     (uart_rx),    // 전송받는 데이터
        .rx_done(w_rx_done),
        .o_data (w_uart_rx),
        .o_rst  (w_rst),
        .tx     (tx)          //전송할 데이터
    );

    total_watch U_total_watch (
        .clk(clk),
        .rst(w_rst),
        .sw(sw),
        .uart_rx(w_uart_rx),
        .uart_rx_done(w_rx_done),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .led(led),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

endmodule


