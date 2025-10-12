`timescale 1ns / 1ps


module top_sensor_fnd (
    input start,
    input clk,
    input rst,
    input echo,
    output trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_start;
    wire [15:0] w_dist;


    btn_debounce U_btn_start (
        .clk  (clk),
        .rst  (rst),
        .i_btn(start),
        .o_btn(w_start)
    );

    fnd_controller U_fnd_cntr (
        .clk(clk),
        .reset(rst),
        .count_data(w_dist),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    sr04_controller U_SR04_cntr (
        .clk(clk),
        .rst(rst),
        .start(w_start),
        .echo(echo),
        .trig(trig),
        .dist(w_dist),
        .dist_done()
    );

    ila_0 u_ila_0 (
        .clk   (clk),
        .probe0(echo),
        .probe1(trig)
    );

endmodule
