`timescale 1ns / 1ps

module traffic_light_density(
    input clk,
    input rst,

    input [2:0] north_density,
    input [2:0] south_density,
    input [2:0] east_density,
    input [2:0] west_density,

    output reg [2:0] light_north,
    output reg [2:0] light_south,
    output reg [2:0] light_east,
    output reg [2:0] light_west
);

    parameter RED = 3'b100;
    parameter YELLOW = 3'b010;
    parameter GREEN = 3'b001;

    parameter NS_GREEN = 2'b00;
    parameter NS_YELLOW = 2'b01;
    parameter EW_GREEN = 2'b10;
    parameter EW_YELLOW = 2'b11;

    reg [1:0] state;
    reg [4:0] count;

    reg [4:0] ns_time;
    reg [4:0] ew_time;

    always @(*)
    begin
        if ((north_density >= 5) || (south_density >= 5))
            ns_time = 20;
        else if ((north_density >= 3) || (south_density >= 3))
            ns_time = 12;
        else
            ns_time = 5;
    end

    always @(*)
    begin
        if ((east_density >= 5) || (west_density >= 5))
            ew_time = 20;
        else if ((east_density >= 3) || (west_density >= 3))
            ew_time = 12;
        else
            ew_time = 5;
    end

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            state <= NS_GREEN;
            count <= 0;
        end
        else
        begin
            case(state)

                NS_GREEN:
                begin
                    if (count < ns_time - 1)
                        count <= count + 1;
                    else
                    begin
                        count <= 0;
                        state <= NS_YELLOW;
                    end
                end

                NS_YELLOW:
                begin
                    if (count < 2)
                        count <= count + 1;
                    else
                    begin
                        count <= 0;
                        state <= EW_GREEN;
                    end
                end

                EW_GREEN:
                begin
                    if (count < ew_time - 1)
                        count <= count + 1;
                    else
                    begin
                        count <= 0;
                        state <= EW_YELLOW;
                    end
                end

                EW_YELLOW:
                begin
                    if (count < 2)
                        count <= count + 1;
                    else
                    begin
                        count <= 0;
                        state <= NS_GREEN;
                    end
                end

                default:
                begin
                    state <= NS_GREEN;
                    count <= 0;
                end

            endcase
        end
    end

    always @(*)
    begin
        light_north = RED;
        light_south = RED;
        light_east  = RED;
        light_west  = RED;

        case(state)

            NS_GREEN:
            begin
                light_north = GREEN;
                light_south = GREEN;
            end

            NS_YELLOW:
            begin
                light_north = YELLOW;
                light_south = YELLOW;
            end

            EW_GREEN:
            begin
                light_east = GREEN;
                light_west = GREEN;
            end

            EW_YELLOW:
            begin
                light_east = YELLOW;
                light_west = YELLOW;
            end

        endcase
    end

endmodule