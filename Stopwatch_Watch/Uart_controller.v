`timescale 1ns / 1ps


module Uart_controller (
    input        clk,
    input        rst,
    input        rx,       // 전송받는 데이터
    output       rx_done,
    output [7:0] o_data,
    output       o_rst,
    output       tx        //전송할 데이터
);

    wire w_bd_tick, w_start, w_rx_done, w_tx_busy;
    wire [7:0] w_dout;

    assign rx_done = w_rx_done;
    assign o_data  = w_dout;

    Baudrate_x8 U_BRx8 (
        .clk(clk),
        .rst(rst),
        .tx_baud_tick(w_bd_tick)
    );

    uart_tx U_uart_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .start(w_rx_done),
        .din(w_dout),  //loop back
        .o_tx_busy(w_tx_busy),
        .o_tx_done(tx_done),
        .o_tx(tx)
    );

    uart_rx U_uart_rx (
        .clk(clk),
        .rst(rst),
        .b_tick(w_bd_tick),
        .rx(rx),
        .o_rx_done(w_rx_done),
        .o_dout(w_dout)
    );

    uart_esc_reset_controller U_RST (
        .clk         (clk),
        .rst         (rst),
        .uart_rx     (w_dout),     // UART 수신 핀
        .uart_rx_done(w_rx_done),
        .reset       (o_rst)       // 타이머로 보낼 리셋 신호
    );


endmodule

module uart_esc_reset_controller (
    input        clk,
    input        rst,           //버튼 reset
    input  [7:0] uart_rx,       // UART 수신 핀
    input        uart_rx_done,
    output       reset          // 타이머로 보낼 리셋 신호
);

    // ESC 키 ASCII 코드
    parameter ESC_KEY = 8'h1B;

    // ESC 키 검출 및 리셋 펄스 생성
    reg esc_detected;

    // ESC 키 검출 로직
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            esc_detected <= 0;

        end else begin
            esc_detected <= 0;
            // UART로 데이터가 수신되고 ESC 키인지 확인
            if (uart_rx_done) begin
                if (uart_rx == ESC_KEY) begin
                    esc_detected <= 1;  // 1클럭 펄스 생성
                end
            end
        end
    end

    // 최종 리셋 신호 (물리적 버튼 또는 ESC 키)
    assign reset = rst | esc_detected;

endmodule
