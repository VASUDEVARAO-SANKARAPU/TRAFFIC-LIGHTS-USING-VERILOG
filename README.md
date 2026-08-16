# Traffic Light Controller Using Verilog HDL

This project implements a four-way traffic light controller in Verilog HDL, using a finite-state-machine-based control sequence to cycle the north, south, east, and west lights through a fixed pattern.

## 1. Project Overview

The controller manages traffic lights for four directions — North, South, East, and West. It is built around a clocked FSM that moves through six traffic-control states, each holding a specific combination of light values for all four directions.

Based on `TL.v`, the design uses:

- A `clk` input that drives all state transitions
- An asynchronous `rst` input that returns the controller to the first state
- A 3-bit `state` register that tracks the current FSM state
- A 4-bit `count` register that times how long the controller stays in each state
- Six states (`STATE1` through `STATE6`) that together form one full traffic cycle
- Four 3-bit registered outputs (`light_north`, `light_south`, `light_east`, `light_west`) representing the light status for each direction

## 2. Project Objective

This project was built to practice a slightly larger FSM than a basic 2-state design, and to combine state-based control with a counter for timed transitions. It demonstrates:

- Finite State Machine (FSM) design with six states
- Sequential logic (state and counter updates on the clock edge)
- Combinational-style output logic driven by the current state
- Using a counter register to control how long each state is held
- Clock-driven state transitions
- Asynchronous reset behavior
- RTL simulation and waveform analysis in Vivado

## 3. How the Controller Works

```text
Clock + Reset
      |
      v
Initialize state = STATE1, count = 0
      |
      v
Current State (STATE1 ... STATE6)
      |
      v
Counter Checks State Duration (count vs TIME_x)
      |
      +------ count < TIME_x ------> count <= count + 1, stay in same state
      |
      +------ count == TIME_x -----> state <= next state, count <= 0
                                              |
                                              v
                                 Output logic updates the four
                                 light_* outputs for the new state
                                              |
                                              v
                                     Cycle repeats from STATE1
                                     after STATE6 completes
```

State transitions and the counter update occur on the **positive edge of `clk`**. The `rst` input is asynchronous — whenever `rst` goes high, `state` is forced to `STATE1` and `count` is forced to `0` immediately, independent of the clock edge.

## 4. FSM State Sequence

The six states are declared as `parameter` values `STATE1 = 0` through `STATE6 = 5`, and each one drives a fixed combination of light outputs.

Looking at the light values used in the code, each of the four outputs only ever takes one of three values across the full cycle: `3'b001`, `3'b010`, and `3'b100`. Tracing how each individual light output changes from state to state, every light always moves in the same order — `3'b001` → `3'b010` → `3'b100` → (back to `3'b001` at the start of the next cycle) — and never skips or reverses. That pattern matches the standard sequence a traffic light follows (green, then yellow, then red), so based on the code's behavior:

- `3'b001` = **Green**
- `3'b010` = **Yellow**
- `3'b100` = **Red**

| State | North | South | East | West | Duration (count condition) |
|-------|-------|-------|------|------|------------------------------|
| `STATE1` | Green (`001`) | Green (`001`) | Red (`100`) | Red (`100`) | Held while `count < TIME_7` (`TIME_7 = 7`) |
| `STATE2` | Green (`001`) | Yellow (`010`) | Red (`100`) | Red (`100`) | Held while `count < TIME_2` (`TIME_2 = 2`) |
| `STATE3` | Green (`001`) | Red (`100`) | Green (`001`) | Red (`100`) | Held while `count < TIME_5` (`TIME_5 = 5`) |
| `STATE4` | Yellow (`010`) | Red (`100`) | Yellow (`010`) | Red (`100`) | Held while `count < TIME_2` (`TIME_2 = 2`) |
| `STATE5` | Red (`100`) | Red (`100`) | Red (`100`) | Green (`001`) | Held while `count < TIME_3` (`TIME_3 = 3`) |
| `STATE6` | Red (`100`) | Red (`100`) | Red (`100`) | Yellow (`010`) | Held while `count < TIME_2` (`TIME_2 = 2`) |

On the timing: the parameters `TIME_7`, `TIME_5`, `TIME_3`, and `TIME_2` are **clock-cycle counts**, not real seconds — the counter increments once per clock edge while `count < TIME_x`, and the state changes on the clock edge where `count` reaches `TIME_x`. So a state defined with `TIME_7` is actually held for 8 clock cycles in total (`count` runs 0 through 7 before the transition fires), and a state defined with `TIME_2` is held for 3 clock cycles, and so on — one more cycle than the `TIME_x` value itself, since the transition cycle is included.

## 5. State Transition Flow

```text
STATE1
   |
   v
STATE2
   |
   v
STATE3
   |
   v
STATE4
   |
   v
STATE5
   |
   v
STATE6
   |
   v
STATE1  (cycle repeats)
```

The controller cycles through all six states in this fixed order and then loops back to `STATE1`, repeating indefinitely as long as `rst` is not asserted. The `count` register is what actually paces this — it increments every clock cycle while the current state's condition (`count < TIME_x`) holds true, and once `count` reaches that state's threshold, the state-control block moves `state` to the next value and resets `count` back to `0` for the new state.

## 6. Input and Output Signals

| Signal | Direction | Width | Description |
|--------|-----------|------:|-------------|
| `clk` | Input | 1 bit | Clock input; state and counter updates happen on its rising edge |
| `rst` | Input | 1 bit | Active-high asynchronous reset; forces `state` to `STATE1` and `count` to `0` |
| `light_north` | Output | 3 bits | Light status for the north direction (`001`=Green, `010`=Yellow, `100`=Red) |
| `light_south` | Output | 3 bits | Light status for the south direction |
| `light_east` | Output | 3 bits | Light status for the east direction |
| `light_west` | Output | 3 bits | Light status for the west direction |

## 7. Verilog Design Explanation

### State and counter registers

```verilog
reg [2:0] state;
reg [3:0] count;
```

`state` holds the current FSM state (only 3 values, 0–5, are actually used out of the 8 possible with 3 bits). `count` is a 4-bit register used purely as a timer within each state — it counts up from 0 and is compared against that state's `TIME_x` parameter to decide when to move on.

### State-control logic

This is handled in the `always @(posedge clk or posedge rst)` block. On every rising clock edge, if `rst` is high, `state` and `count` are both cleared back to `STATE1` / `0`. Otherwise, a `case (state)` statement checks the current state's duration condition: if `count` hasn't yet reached that state's threshold, `count` increments and `state` stays the same; once the threshold is reached, `state` moves to the next state in sequence and `count` resets to `0` for the next state's timing.

### Traffic light output logic

This is handled separately in the `always @(state)` block. It's a `case (state)` statement that assigns fixed values to `light_north`, `light_south`, `light_east`, and `light_west` for each of the six states, plus a `default` branch that sets all four outputs to `3'b000` if `state` ever holds a value outside `STATE1`–`STATE6`. Since this block is only sensitive to `state` (not `clk`), the outputs update combinationally whenever `state` changes, rather than being clocked directly — though in practice they only ever change right after a state transition on the clock edge.

## 8. Testbench

`TL_tb.v` instantiates the controller as `dut` and connects it to `clk`, `rst`, and the four light outputs. It doesn't check for any expected values — it's a simulation-driving testbench rather than a self-checking one, meant for observing behavior on the waveform rather than automatically verifying it.

- **Clock generation:** `clk` starts at `0`, and `forever #10 clk = ~clk;` toggles it every 10 ns, giving a clock period of 20 ns.
- **Reset sequence:** `rst` starts low, is driven high for 100 ns (from t=100ns to t=200ns), and is then driven low again for the rest of the simulation.
- **Run duration:** after the reset pulse, the simulation continues running for 200,000 ns before `$finish` is called, which is enough time to observe the controller cycling through the full six-state sequence multiple times.

## 9. Simulation Results

![Traffic Light Controller Simulation Waveform](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/TRAFFIC-LIGHTS-USING-VERILOG/refs/heads/main/images/timing_Traf_D.jpeg)

From the waveform:

- `clk` toggles continuously at a fixed rate throughout the simulation, matching the `#10` clock generation in the testbench.
- `rst` is visible going high briefly near the start of the simulation before returning low, matching the reset pulse applied in the testbench.
- `light_north`, `light_south`, `light_east`, and `light_west` are each shown as 3-bit values, and the waveform displays them changing between the numeric values `1`, `2`, and `4` — these correspond to `3'b001` (Green), `3'b010` (Yellow), and `3'b100` (Red) respectively.
- Each of the four light signals changes at a different pace and holds its value for a different length of time before switching, which is consistent with the different `TIME_x` durations assigned to each state in the code.
- The light values repeat their pattern over time, which is consistent with the controller cycling from `STATE1` through `STATE6` and back to `STATE1` continuously after reset is released.

## 10. RTL / Elaborated Schematic

![Traffic Light Controller RTL Schematic](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/TRAFFIC-LIGHTS-USING-VERILOG/refs/heads/main/images/schematic_Traf_D.jpeg)

This is the elaborated design view generated by Vivado from the RTL code, before any technology mapping to actual FPGA logic cells — it shows the generic hardware structure the tool infers from the Verilog description, not a physical FPGA implementation.

Visible in the schematic:

- **`state_reg[2:0]`** — the state register, along with **`count_reg[3:0]`** — the counter register. Both are the sequential elements coming from the `always @(posedge clk or posedge rst)` block.
- A large number of **multiplexer (`MUX`) blocks** driving both `state_i` and `count_i` — these implement the `case (state)` comparisons and the count-vs-`TIME_x` conditions from the state-control logic.
- Additional mux logic feeding the four light outputs (`light_north`, `light_south`, `light_east`, `light_west`) on the right side, corresponding to the second `always @(state)` output block.
- The tool reports **29 cells and 69 nets** for this design, which reflects the added complexity of the counter and six-state comparison logic compared to a simpler 2-state FSM.

## 11. Tools Used

- Verilog HDL
- Xilinx Vivado
- RTL Elaboration
- Behavioral Simulation
- Verilog Testbench

## 12. Project Files

| File | Purpose |
|------|---------|
| `TL.v` | Main traffic light controller (FSM, counter, output logic) |
| `TL_tb.v` | Testbench used to drive the clock/reset and run the simulation |
| `images/schematic_Traf_D.jpeg` | Elaborated RTL schematic from Vivado |
| `images/timing_Traf_D.jpeg` | Behavioral simulation waveform |
| `README.md` | Project documentation |

## 13. How to Run the Project in Vivado

1. Open Xilinx Vivado.
2. Create a new RTL project.
3. Add `TL.v` as the design source.
4. Add `TL_tb.v` as the simulation source.
5. Set `Traffic_Light_Controller_TB` as the simulation top module if Vivado doesn't pick it up automatically.
6. Run **Behavioral Simulation** from the Flow Navigator.
7. Add `light_north`, `light_south`, `light_east`, and `light_west` to the waveform window if they aren't already listed.
8. Observe the state-dependent light sequence as the simulation progresses through the reset pulse and the repeating six-state cycle.

## 14. Learning Outcomes

- Designing a multi-state FSM in Verilog, beyond a simple two-state design
- Using a counter register alongside a state register to control timed state transitions
- Understanding the split between sequential logic (state/counter updates) and the state-driven output logic
- Implementing and testing asynchronous reset behavior
- Writing a basic, non-self-checking testbench for clock and reset generation
- Running behavioral simulation in Vivado and reading a multi-signal waveform
- Interpreting an RTL schematic and connecting it back to the original Verilog description

## 15. Possible Future Improvements

These are potential extensions and are not part of the current implementation:

- Making the `TIME_x` duration values configurable instead of fixed parameters
- Adding vehicle sensors for adaptive/traffic-responsive control
- Adding a pedestrian crossing signal and control logic
- Adding emergency-vehicle priority handling
- Adding a seven-segment countdown display for the active state's remaining time
- Implementing and testing the design on an actual FPGA board
- Building out more advanced traffic scheduling (e.g., turn lanes, variable cycle lengths)

## 16. Conclusion

This project shows how a repeating, real-world sequence like a traffic light cycle can be represented cleanly as a Verilog FSM, using a state register combined with a counter for timing. Building it end-to-end — from the RTL code, to a driving testbench, to reading the simulation waveform and the elaborated schematic — reinforced core RTL design ideas: sequential vs. combinational logic, asynchronous reset handling, and how a `case`-based state machine actually maps down to registers and multiplexers in hardware.
