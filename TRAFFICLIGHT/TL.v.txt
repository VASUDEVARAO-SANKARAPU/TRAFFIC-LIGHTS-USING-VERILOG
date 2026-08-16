`timescale 1ns / 1ps

module Traffic_Light_Controller(
    input clk,
    input rst,

    output reg [2:0] light_north,
    output reg [2:0] light_south,
    output reg [2:0] light_east,
    output reg [2:0] light_west
);

    // Traffic light states
    parameter STATE1 = 0;
    parameter STATE2 = 1;
    parameter STATE3 = 2;
    parameter STATE4 = 3;
    parameter STATE5 = 4;
    parameter STATE6 = 5;

    reg [2:0] state;
    reg [3:0] count;

    // Time for each state
    parameter TIME_7 = 7;
    parameter TIME_5 = 5;
    parameter TIME_3 = 3;
    parameter TIME_2 = 2;

    // State control
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            state <= STATE1;
            count <= 0;
        end
        else
        begin
            case (state)

                STATE1:
                    if (count < TIME_7)
                    begin
                        state <= STATE1;
                        count <= count + 1;
                    end
                    else
                    begin
                        state <= STATE2;
                        count <= 0;
                    end

                STATE2:
                    if (count < TIME_2)
                    begin
                        state <= STATE2;
                        count <= count + 1;
                    end
                    else
                    begin
                        state <= STATE3;
                        count <= 0;
                    end

                STATE3:
                    if (count < TIME_5)
                    begin
                        state <= STATE3;
                        count <= count + 1;
                    end
                    else
                    begin
                        state <= STATE4;
                        count <= 0;
                    end

                STATE4:
                    if (count < TIME_2)
                    begin
                        state <= STATE4;
                        count <= count + 1;
                    end
                    else
                    begin
                        state <= STATE5;
                        count <= 0;
                    end

                STATE5:
                    if (count < TIME_3)
                    begin
                        state <= STATE5;
                        count <= count + 1;
                    end
                    else
                    begin
                        state <= STATE6;
                        count <= 0;
                    end

                STATE6:
                    if (count < TIME_2)
                    begin
                        state <= STATE6;
                        count <= count + 1;
                    end
                    else
                    begin
                        state <= STATE1;
                        count <= 0;
                    end

                default:
                begin
                    state <= STATE1;
                    count <= 0;
                end

            endcase
        end
    end

    // Traffic light control
    always @(state)
    begin
        case (state)

            STATE1:
            begin
                light_north <= 3'b001;
                light_south <= 3'b001;
                light_east  <= 3'b100;
                light_west  <= 3'b100;
            end

            STATE2:
            begin
                light_north <= 3'b001;
                light_south <= 3'b010;
                light_east  <= 3'b100;
                light_west  <= 3'b100;
            end

            STATE3:
            begin
                light_north <= 3'b001;
                light_south <= 3'b100;
                light_east  <= 3'b001;
                light_west  <= 3'b100;
            end

            STATE4:
            begin
                light_north <= 3'b010;
                light_south <= 3'b100;
                light_east  <= 3'b010;
                light_west  <= 3'b100;
            end

            STATE5:
            begin
                light_north <= 3'b100;
                light_south <= 3'b100;
                light_east  <= 3'b100;
                light_west  <= 3'b001;
            end

            STATE6:
            begin
                light_north <= 3'b100;
                light_south <= 3'b100;
                light_east  <= 3'b100;
                light_west  <= 3'b010;
            end

            default:
            begin
                light_north <= 3'b000;
                light_south <= 3'b000;
                light_east  <= 3'b000;
                light_west  <= 3'b000;
            end

        endcase
    end

endmodule