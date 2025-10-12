`timescale 1ns / 1ps

module fnd_controllr (
    input clk,
    input reset,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    input mode0,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);
    wire [3:0] w_bcd, w_msec_1, w_msec_10, w_sec_1, w_sec_10,w_min_1,w_min_10,w_hour_1,w_hour_10;
    wire w_oclk;
    wire [3:0] w_bcd_1, w_bcd_2;
    wire [2:0] fnd_sel;
    wire [3:0] w_dp_onoff;

    // fnd_sel 연결하기.
    clk_div U_CLK_Div (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_oclk)
    );
    counter_8 U_Counter_8 (
        .clk(w_oclk),
        .reset(reset),
        .fnd_sel(fnd_sel)
    );
    decoder_2x4 U_Decoder_2x4 (
        .fnd_sel(fnd_sel[1:0]),
        .fnd_com(fnd_com)
    );
    digit_splitter U_DS_msec (
        .time_data(msec),
        .time_1(w_msec_1),
        .time_10(w_msec_10)
    );

    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_DS_sec (
        .time_data(sec),
        .time_1(w_sec_1),
        .time_10(w_sec_10)
    );

    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_DS_min (
        .time_data(min),
        .time_1(w_min_1),
        .time_10(w_min_10)
    );

    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_DS_hour (
        .time_data(hour),
        .time_1(w_hour_1),
        .time_10(w_hour_10)
    );

    mux_8x1 U_MUX_8x1_1 (
        .sel(fnd_sel),
        .digit_1(w_msec_1),
        .digit_10(w_msec_10),
        .digit_100(w_sec_1),
        .digit_1000(w_sec_10),
        .dot_on(w_dp_onoff),
        .bcd(w_bcd_1)
    );

    mux_8x1 U_MUX_8x1_2 (
        .sel(fnd_sel),
        .digit_1(w_min_1),
        .digit_10(w_min_10),
        .digit_100(w_hour_1),
        .digit_1000(w_hour_10),
        .dot_on(w_dp_onoff),
        .bcd(w_bcd_2)
    );

    time_selection U_SW (
        .msec_sec(w_bcd_1),
        .min_hour(w_bcd_2),
        .sel(mode0),
        .bcd(w_bcd)
    );

    bcd U_BCD (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    Dot_Onoff U_DP_OnOFF (
        .clk(clk),
        .rst(reset),
        .msec(msec),
        .dot_onoff(w_dp_onoff)
    );
endmodule

// clk divider
// 1khz
module clk_div (
    input  clk,
    input  reset,
    output o_clk
);
    // clk 100_000_000, r_count = 100_000
    //reg [16:0] r_counter;
    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk     <= 1'b0;
        end else begin
            if (r_counter == 1_000 - 1) begin  // 1khz period
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

endmodule

// 8진 카운터
module counter_8 (
    input        clk,
    input        reset,
    output [2:0] fnd_sel
);
    reg [2:0] r_counter;
    assign fnd_sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end
    end
endmodule

module decoder_2x4 (
    input      [1:0] fnd_sel,
    output reg [3:0] fnd_com
);
    always @(fnd_sel) begin
        case (fnd_sel)
            2'b00:   fnd_com = 4'b1110;  // fnd 1의 자리 On,
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule


module mux_8x1 (
    input  [2:0] sel,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] dot_on,
    output [3:0] bcd
);
    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000: r_bcd = digit_1;
            3'b001: r_bcd = digit_10;
            3'b010: r_bcd = digit_100;
            3'b011: r_bcd = digit_1000;
            3'b100: r_bcd = 4'hf;
            3'b101: r_bcd = 4'hf;
            3'b110: r_bcd = dot_on;
            3'b111: r_bcd = 4'hf;
            default r_bcd = 4'hf;
        endcase
    end

endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH - 1:0] time_data,
    output [3:0] time_1,
    output [3:0] time_10

);

    assign time_1  = time_data % 10;
    assign time_10 = (time_data / 10) % 10;


endmodule

module bcd (
    input  [3:0] bcd,
    output [7:0] fnd_data
);

    reg [7:0] r_fnd_data;

    assign fnd_data = r_fnd_data;

    // 조합논리 combinational , 행위수준 모델링.

    always @(bcd) begin
        case (bcd)
            4'h00: r_fnd_data = 8'hc0;
            4'h01: r_fnd_data = 8'hf9;
            4'h02: r_fnd_data = 8'ha4;
            4'h03: r_fnd_data = 8'hb0;
            4'h04: r_fnd_data = 8'h99;
            4'h05: r_fnd_data = 8'h92;
            4'h06: r_fnd_data = 8'h82;
            4'h07: r_fnd_data = 8'hf8;
            4'h08: r_fnd_data = 8'h80;
            4'h09: r_fnd_data = 8'h90;
            4'he: r_fnd_data = 8'h7f;
            4'hf: r_fnd_data = 8'hff;
            default: r_fnd_data = 8'hff;
        endcase
    end

endmodule

//2x1 mux
module time_selection (
    input [3:0] msec_sec,
    input [3:0] min_hour,
    input sel, //mode[0]
    // input [7:0] uart_rx,
    // input uart_rx_done,
    output [3:0] bcd
);

    localparam SEC_MSEC = 0, HOUR_MIN = 0;
    // reg c_state, n_state;
    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    // always @(posedge clk, posedge rst) begin
    //     if (rst) c_state <= SEC_MSEC;
    //     else c_state <= n_state;
    // end
    // always @(*) begin
    //     n_state = c_state;
    //     case (c_state)
    //         SEC_MSEC: begin
    //             r_bcd = msec_sec;
    //             if (sel) begin
    //                 n_state = HOUR_MIN;
    //             end else if (uart_rx_done) begin
    //                 if ((uart_rx == 8'h4e) || (uart_rx == 8'h6e)) begin  //n
    //                     n_state = HOUR_MIN;
    //                 end

    //             end
    //         end

    //         HOUR_MIN: begin
    //             r_bcd = min_hour;
    //             if (sel == 0) begin
    //                 n_state = SEC_MSEC;
    //             end else if (uart_rx_done) begin
    //                 if ((uart_rx == 8'h4e) || (uart_rx == 8'h6e)) begin  //n
    //                     n_state = HOUR_MIN;
    //                 end

    //             end

    //         end

    //     endcase
    // end

    always @(*) begin
        case(sel)
            1'b0: begin
                r_bcd = msec_sec;
            end
            1'b1: begin
                r_bcd = min_hour;
            end
        endcase
        
    end
endmodule

//비교기
module Dot_Onoff (
    input clk,
    input rst,
    input [6:0] msec,
    output reg [3:0] dot_onoff
);

    always @(posedge clk, posedge rst) begin
        if (rst) dot_onoff <= 0;
        else if (msec >= 50) dot_onoff <= 4'he;
        else dot_onoff <= 4'hf;
    end

endmodule
