`timescale 1ns / 1ps

module Traffic_Light_Controller_TB;

    reg clk;
    reg rst;

    wire [2:0] light_north;
    wire [2:0] light_south;
    wire [2:0] light_east;
    wire [2:0] light_west;

    // Connect the testbench to the traffic light controller
    Traffic_Light_Controller dut (
        .clk(clk),
        .rst(rst),
        .light_north(light_north),
        .light_south(light_south),
        .light_east(light_east),
        .light_west(light_west)
    );

    // Generate clock
    initial
    begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Reset and simulation
    initial
    begin
        rst = 1'b0;

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #200000;
        $finish;
    end

endmodule