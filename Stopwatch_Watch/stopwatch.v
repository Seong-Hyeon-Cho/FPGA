`timescale 1ns / 1ps


module top_stopwatch (
    input clk,
    input rst,
    input btnR_Clear,
    input btnL_RunStop,
    input [7:0] uart_rx,
    input uart_rx_done,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_runstop, w_clear;


    stopwatch_dp U_StopWatch_DP (
        .clk(clk),
        .rst(rst),
        .run_stop(w_runstop),
        .clear(w_clear),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    stopwatch_cu U_CU (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .i_clear(btnR_Clear),
        .i_runstop(btnL_RunStop),
        .o_clear(w_clear),
        .o_runstop(w_runstop)
    );



endmodule
