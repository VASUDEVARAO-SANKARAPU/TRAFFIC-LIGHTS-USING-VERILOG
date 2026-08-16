`timescale 1ns / 1ps

module traffic_light_density_tb;

    reg clk;
    reg rst;

    reg [2:0] north_density;
    reg [2:0] south_density;
    reg [2:0] east_density;
    reg [2:0] west_density;

    wire [2:0] light_north;
    wire [2:0] light_south;
    wire [2:0] light_east;
    wire [2:0] light_west;

    traffic_light_density dut(
        .clk(clk),
        .rst(rst),
        .north_density(north_density),
        .south_density(south_density),
        .east_density(east_density),
        .west_density(west_density),
        .light_north(light_north),
        .light_south(light_south),
        .light_east(light_east),
        .light_west(light_west)
    );

    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial
    begin
        rst = 1;

        north_density = 0;
        south_density = 0;
        east_density = 0;
        west_density = 0;

        #20;
        rst = 0;

        north_density = 1;
        south_density = 1;
        east_density = 1;
        west_density = 1;

        #150;

        north_density = 7;
        south_density = 6;
        east_density = 1;
        west_density = 1;

        #300;

        north_density = 1;
        south_density = 1;
        east_density = 7;
        west_density = 6;

        #300;

        north_density = 3;
        south_density = 3;
        east_density = 3;
        west_density = 3;

        #200;

        $finish;
    end

    initial
    begin
        $monitor(
            "Time=%0t | N_D=%0d S_D=%0d E_D=%0d W_D=%0d | N=%b S=%b E=%b W=%b | State=%0d Count=%0d",
            $time,
            north_density,
            south_density,
            east_density,
            west_density,
            light_north,
            light_south,
            light_east,
            light_west,
            dut.state,
            dut.count
        );
    end

endmodule