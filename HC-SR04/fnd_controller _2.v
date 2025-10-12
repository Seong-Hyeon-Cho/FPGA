`timescale 1ns / 1ps

module fnd_controller (
    input clk,
    input reset,
    input [15:0] count_data,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);
    wire [3:0] w_bcd, w_digit_1, w_digit_10, w_digit_100, w_digit_1000;

    wire w_oclk;
    wire [1:0] w_fnd_sel;
   
    clk_div U_Clk_Div (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_oclk)
    );
    counter U_Counter (
        .clk(w_oclk),
        .reset(reset),
        .fnd_sel(w_fnd_sel)
    );


    digit_splitter U_DS (
        .ds_data(count_data),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );
    mux_4x1 U_MUX (
        .sel(w_fnd_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .bcd(w_bcd)
    );
    bcd U_BCD (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    decoder_2x4 U_De_2x4 (
        .fnd_sel(w_fnd_sel),
        .fnd_com(fnd_com)
    );

endmodule


module decoder_2x4 (
    input [1:0] fnd_sel,
    output reg [3:0] fnd_com
);
    always @(fnd_sel) begin
        case (fnd_sel)
            2'b00:   fnd_com = 4'b1110;//e
            2'b01:   fnd_com = 4'b1101;//d
            2'b10:   fnd_com = 4'b1011;//b
            2'b11:   fnd_com = 4'b0111;//7
            default: fnd_com = 4'b1111;  //case문은 가급적 default 작성
        endcase
    end
endmodule

module clk_div (
    input  clk,
    input  reset,
    output o_clk
);

    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 0;  //r_clk <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 0;
            end
        end
    end

endmodule


module counter (
    input clk,  //basys3 system-clk = 100Mhz
    input reset,
    output [1:0] fnd_sel
);
    reg [1:0] r_counter;
    assign fnd_sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end
    end
endmodule

module mux_4x1 (  //자릿수를 sel을 통해 선택
    input  [1:0] sel,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    output [3:0] bcd
);

    reg [3:0] r_bcd;

    assign bcd = r_bcd;
    //mux 설계
    always @(*) begin  //(*) 모든 입력 감시
        case (sel)
            2'b00: r_bcd = digit_1;
            2'b01: r_bcd = digit_10;
            2'b10: r_bcd = digit_100;
            2'b11: r_bcd = digit_1000;
        endcase

    end

endmodule

module digit_splitter (

    input [15:0] ds_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);

    assign digit_1 = ds_data % 10;
    assign digit_10 = (ds_data / 10) % 10;
    assign digit_100 = (ds_data / 100) % 10;
    assign digit_1000 = (ds_data / 1000) % 10;

endmodule

module bcd (
    input  [3:0] bcd,
    output [7:0] fnd_data

);


    reg [7:0] r_fnd_data;
    assign fnd_data = r_fnd_data;


    always @(bcd) begin
        case (bcd)
            4'h00:   r_fnd_data = 8'hc0;
            4'h01:   r_fnd_data = 8'hf9;
            4'h02:   r_fnd_data = 8'ha4;
            4'h03:   r_fnd_data = 8'hb0;
            4'h04:   r_fnd_data = 8'h99;
            4'h05:   r_fnd_data = 8'h92;
            4'h06:   r_fnd_data = 8'h82;
            4'h07:   r_fnd_data = 8'hf8;
            4'h08:   r_fnd_data = 8'h80;
            4'h09:   r_fnd_data = 8'h90;
            default: r_fnd_data = 8'hff;

        endcase
    end
endmodule
