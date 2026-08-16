# TRAFFIC LIGHTS USING VERILOG. 

PROJECT_IDEA

The idea of this project is to design a four-way traffic light controller using Verilog HDL. The system controls the traffic lights at a four-road intersection: North, South, East, and West. The controller uses a Finite State Machine (FSM) with six states to determine which direction receives the green, yellow, or red signal at a particular time. Each traffic light is represented using a 3-bit output, corresponding to the three light conditions.

The controller is designed so that traffic moves through the intersection in a predefined sequence. The timing of each state is controlled using an internal counter, with different states having different durations. The six states use timing values of 7, 2, 5, 2, 3, and 2 clock counts, respectively. After the sixth state, the controller returns to the first state and continuously repeats the sequence.

WORKING_PROCEDURE 

The operation starts with the rst signal. When reset is activated, the controller is initialized to STATE1 and the internal counter is set to zero. The controller then operates according to the incoming clock signal. The state-control logic is triggered on every positive edge of the clock or when reset is activated.

In STATE1, the North and South directions receive the green signal while East and West receive the red signal. This state remains active according to its programmed timing value of 7 clock counts. Once the count is reached, the controller moves to STATE2 and resets the counter.

In STATE2, North remains green, South changes to yellow, and East and West remain red. After the specified 2 clock counts, the controller moves to STATE3. In STATE3, North becomes green, South becomes red, East becomes green, and West remains red. This state operates for 5 clock counts before moving to STATE4.

In STATE4, North and East receive yellow signals while South and West remain red. After 2 clock counts, the controller moves to STATE5. In STATE5, North, South, and East are red while West receives the green signal. This state remains active for 3 clock counts.

In STATE6, West changes to yellow while the other three directions remain red. After 2 clock counts, the controller returns to STATE1, and the complete traffic-light sequence starts again.

The testbench generates the clock using a 10 ns delay between clock transitions and applies the reset at the beginning of the simulation. It then releases the reset, allowing the FSM to move through its different states. The outputs light_north, light_south, light_east, and light_west are monitored in the waveform to verify that the traffic lights change according to the programmed sequence.