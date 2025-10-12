`timescale 1ns / 1ps


module BTN_CONNECT (
    input  clk,
    input  rst,
    input  btnU,
    input  btnD,
    input  btnL,
    input  btnR,
    input  mode1,
    output o_watch_btnU,
    output o_watch_btnD,
    output o_watch_btnL,
    output o_watch_btnR,
    output o_stopwatch_btnL,
    output o_stopwatch_btnR
);

    wire w_btnU, w_btnD, w_btnL, w_btnR,w_mode1;
    btn_debounce U_BD_BU (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );
    btn_debounce U_BD_BD (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );
    btn_debounce U_BD_BL (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );
    btn_debounce U_BD_BR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );

    btn_mode_connection U_BTN_MODE_CONNECTION (
        .btnU(w_btnU),
        .btnD(w_btnD),
        .btnL(w_btnL),
        .btnR(w_btnR),
        // .sw(sw),
        .i_mode1(mode1),
        // .o_mode1(o_mode1),
        .o_stopwatch_btnL(o_stopwatch_btnL),
        .o_stopwatch_btnR(o_stopwatch_btnR),
        .o_watch_btnU(o_watch_btnU),
        .o_watch_btnD(o_watch_btnD),
        .o_watch_btnL(o_watch_btnL),
        .o_watch_btnR(o_watch_btnR)
    );
endmodule

module btn_mode_connection (
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input i_mode1,
    output reg o_stopwatch_btnL,
    output reg o_stopwatch_btnR,
    output reg o_watch_btnU,
    output reg o_watch_btnD,
    output reg o_watch_btnL,
    output reg o_watch_btnR
);

assign o_mode1 = i_mode1;
    always @(*) begin
        case (i_mode1)
            1'b1: begin  //타이머
                o_stopwatch_btnL = btnL;
                o_stopwatch_btnR = btnR;
                o_watch_btnL = 0;
                o_watch_btnR = 0;
                o_watch_btnU = 0;
                o_watch_btnD = 0;

            end
            1'b0: begin  //시계
                o_stopwatch_btnL = 0;
                o_stopwatch_btnR = 0;
                o_watch_btnL = btnL;
                o_watch_btnR = btnR;
                o_watch_btnU = btnU;
                o_watch_btnD = btnD;
            end
        endcase
    end
endmodule

// module sw_uart_mode (
//     input clk,
//     input rst,
//     input sw1,
//     input uart_rx_done,
//     input [7:0] uart_rx,
//     output mode1
// );
//     parameter STOPWATCH = 1'b1, WATCH = 1'b0;
//     reg c_state, n_state;
//     assign mode1 = c_state;
//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state <= WATCH;
//         end else begin
//             c_state <= n_state;
//         end
//     end
//     always @(*) begin
//         n_state = c_state;
//         case (c_state)
//             WATCH: begin
//                 if (sw1) n_state = STOPWATCH;
//                 if (uart_rx_done) begin
//                     if ((uart_rx == 8'h4d) || (uart_rx == 8'h6d))
//                         n_state = STOPWATCH;
//                 end
//             end
//             STOPWATCH: begin
//                 if (sw1 == 0) n_state = WATCH;
//                 if (uart_rx_done) begin
//                     if ((uart_rx == 8'h4d) || (uart_rx == 8'h6d))
//                         n_state = WATCH;
//                 end
//             end
//         endcase
//     end

// endmodule
