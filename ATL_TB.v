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
end

always
begin
    #5 clk = ~clk;
end

initial
begin

    rst = 1;

    north_density = 3'd1;
    south_density = 3'd1;
    east_density = 3'd1;
    west_density = 3'd1;

    #20;

    rst = 0;

 #100;

    north_density = 3'd7;
    south_density = 3'd6;
    east_density = 3'd1;
    west_density = 3'd1;

    #300;

    north_density = 3'd1;
    south_density = 3'd1;
    east_density = 3'd7;
    west_density = 3'd6;

    #300;

    north_density = 3'd3;
    south_density = 3'd3;
    east_density = 3'd3;
    west_density = 3'd3;

    #300;

    $finish;

end

endmodule