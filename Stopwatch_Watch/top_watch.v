`timescale 1ns / 1ps


module top_watch (
    input        clk,
    input        rst,
    input        btnU_timeup,
    input        btnD_timedown,
    input        btnL_shift_left,
    input        btnR_shift_right,
    input sw,
    // input        mode,
    input  [7:0] uart_rx,
    input        uart_rx_done,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_timeup, w_timedown, w_shift_left, w_shift_right;
    wire [1:0] w_field_sel;

    watch_dp U_WATCH_DP (
        .clk(clk),
        .rst(rst),
        .btn_time_up(btnU_timeup),
        .btn_time_down(btnD_timedown),
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .field_sel(w_field_sel),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );


    watch_CU U_WATCH_CU (
        .clk(clk),
        .rst(rst),
        .btn_shift_left(btnL_shift_left),
        .btn_shift_right(btnR_shift_right),
        .sw0(sw), //sw0 표기 시간 변경경
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .o_field_sel(w_field_sel)
    );


endmodule
