`timescale 1ns / 1ps

module tb_dht11_1 ();

    parameter US = 1000;

    reg clk, rst, start, dht11_io_reg, io_en;
    reg  [39:0] dht11_test_data;
    wire [ 3:0] state_led;
    wire dht11_io, valid, done;
    wire [39:0] total_data;

    dht11_controller dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .rhdata(total_data[39:32]),
        .t_data(total_data[23:16]),
        .dht11_done(done),
        .dht11_valid(valid),  // checksum.
        .led(state_led),
        .dht11_io(dht11_io)
    );

    assign dht11_io = (io_en) ? 1'bz : dht11_io_reg;

    always #5 clk = ~clk;

    integer i = 0;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        start = 0;
        dht11_io_reg = 0;
        io_en = 1;
        // dht11_test_data = 40'b10101010_00001111_11000110_00000000_01111111;
        dht11_test_data = 40'b10101010_00001111_11000110_00000000_01111110; //valid test
        #20;
        rst = 0;

        #20;
        start = 1;
        #20;
        start = 0;

        wait (!dht11_io);
        wait (dht11_io);

        #(30 * US);  // 30usec
        io_en = 0;
        dht11_io_reg = 0;
        #(80 * US);
        // #(20 * US);  //error test
        dht11_io_reg = 1;
        #(80 * US);
        for (i = 0; i < 40; i = i + 1) begin
            dht11_io_reg = 0;
            #(50 * US);  // data sync

            if (dht11_test_data[39-i] == 0) begin
                dht11_io_reg = 1;
                #(29 * US);
            end else begin
                dht11_io_reg = 1;
                #(68 * US);
            end
        end
        dht11_io_reg = 0;
        #(50 * US);
        io_en = 1;
        #50000;
        $stop;
    end



endmodule
