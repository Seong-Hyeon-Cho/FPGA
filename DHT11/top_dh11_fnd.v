`timescale 1ns / 1ps


module top_dh11_fnd (
    input clk,
    input rst,
    input start,
    output [3:0] led,
    output led_done,
    output led_valid,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    inout dht11_io
);

    wire w_start;
    wire [7:0] w_rhdata, w_t_data;

    dht11_controller U_DHT11 (
        .clk(clk),
        .rst(rst),
        .start(w_start),
        .dht11_done(led_done),
        .dht11_valid(led_valid),  //checksum
        .rhdata(w_rhdata),
        .t_data(w_t_data),
        .led(led),
        .dht11_io(dht11_io)
    );

    fnd_controller U_Fnd (
        .clk(clk),
        .reset(rst),
        .rhdata(w_rhdata),
        .t_data(w_t_data),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    btn_debounce U_btn (
        .clk  (clk),
        .rst  (rst),
        .i_btn(start),
        .o_btn(w_start)
    );
endmodule
