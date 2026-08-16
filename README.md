# Density-Based Adaptive Traffic Light Controller Using Verilog HDL

This project implements a four-direction traffic light controller in Verilog HDL where the green-light duration for each direction group is decided dynamically based on digital traffic-density inputs, instead of using a fixed timing value for every cycle.

## 1. Project Overview

A standard traffic-light controller gives every direction the same green duration on every cycle, regardless of how much traffic is actually waiting. That wastes green time on a light direction with almost no traffic, and can under-serve a direction that's genuinely busy.

This design tries to address that by reading in a traffic-density level for each of the four directions and using it to pick a longer or shorter green time:

```text
Traffic Density Inputs
        |
        v
Density Evaluation
        |
        v
Calculate Green Time
        |
        v
FSM Controls Traffic Lights
        |
        v
Green → Yellow → Opposite Green → Yellow
        |
        v
Continuous Operation
```

The four directions are grouped and controlled in pairs — **North-South** as one group, **East-West** as the other — the same way a real intersection typically operates, rather than controlling all four lights fully independently.

## 2. Project Objective

The goal was to design an RTL-based traffic-light controller that:

- Uses a finite state machine to sequence through the light phases
- Accepts digital traffic-density levels as inputs
- Adjusts the green-light duration based on those density levels
- Still maintains a fixed, safe yellow transition between green phases
- Drives four 3-bit traffic-light outputs
- Can be verified through Verilog simulation

## 3. Features

Based strictly on `Advanced_tl.v`:

- Four-direction traffic-light control (North, South, East, West)
- FSM-based control with four states
- Digital traffic-density inputs (3 bits each, values 0–7)
- Adaptive North-South green timing, based on `north_density`/`south_density`
- Adaptive East-West green timing, based on `east_density`/`west_density`
- Three density-based timing levels (low / medium / high)
- Fixed yellow interval for both direction groups
- Asynchronous reset
- Clock-driven state transitions
- A Verilog testbench (`ATL_TB.v`) covering multiple density scenarios
- Vivado RTL elaboration and behavioral simulation

## 4. Inputs and Outputs

| Signal | Direction | Width | Description |
|--------|-----------|------:|-------------|
| `clk` | Input | 1 bit | Clock signal |
| `rst` | Input | 1 bit | Asynchronous reset |
| `north_density` | Input | 3 bits | Traffic-density level for North (0–7) |
| `south_density` | Input | 3 bits | Traffic-density level for South (0–7) |
| `east_density` | Input | 3 bits | Traffic-density level for East (0–7) |
| `west_density` | Input | 3 bits | Traffic-density level for West (0–7) |
| `light_north` | Output | 3 bits | North traffic-light state |
| `light_south` | Output | 3 bits | South traffic-light state |
| `light_east` | Output | 3 bits | East traffic-light state |
| `light_west` | Output | 3 bits | West traffic-light state |

Since each density input is 3 bits wide, it can represent a digital density level from 0 to 7. These are **not** percentages or real sensor readings — in the current design they're just numeric levels applied directly as test inputs.

The 3-bit light encoding used in the code:

| Value | Meaning |
|-------|---------|
| `3'b001` | Green |
| `3'b010` | Yellow |
| `3'b100` | Red |

## 5. Density-to-Timing Logic

This is the core feature of the project. The controller calculates two separate green-time values — one for North-South, one for East-West — combinationally, based on whichever direction in that group has the higher density.

### North-South Timing

| Density Condition | Green Duration |
|--------------------|----------------:|
| `north_density >= 5` OR `south_density >= 5` | 20 clock counts |
| `north_density >= 3` OR `south_density >= 3` | 12 clock counts |
| Otherwise | 5 clock counts |

### East-West Timing

| Density Condition | Green Duration |
|---------------------|----------------:|
| `east_density >= 5` OR `west_density >= 5` | 20 clock counts |
| `east_density >= 3` OR `west_density >= 3` | 12 clock counts |
| Otherwise | 5 clock counts |

These conditions are checked in order in the code, so the highest applicable density band wins — if either direction in a group is at or above the "high" threshold, that group gets the long green time, regardless of the other direction's value. Both `ns_time` and `ew_time` are computed in their own `always @(*)` blocks, so they update combinationally, immediately reflecting the current density inputs rather than being sampled only at specific clock edges.

The yellow interval is fixed at **3 clock counts** for both groups, regardless of density.

## 6. FSM Architecture

| State | Active Direction | Light Behavior |
|-------|--------------------|------------------|
| `NS_GREEN` | North-South | North/South Green, East/West Red |
| `NS_YELLOW` | North-South | North/South Yellow, East/West Red |
| `EW_GREEN` | East-West | East/West Green, North/South Red |
| `EW_YELLOW` | East-West | East/West Yellow, North/South Red |

In the output logic, all four lights are first defaulted to `RED`, and then the relevant pair is overridden to `GREEN` or `YELLOW` depending on the current state. This means red doesn't need to be explicitly assigned in every state — it's just what's left over unless the state logic says otherwise.

## 7. State Transition Diagram

```text
                 +-------------+
                 |  NS_GREEN   |
                 +-------------+
                        |
                  ns_time counts
                        |
                        v
                 +-------------+
                 |  NS_YELLOW  |
                 +-------------+
                        |
                  3 clock counts
                        |
                        v
                 +-------------+
                 |  EW_GREEN   |
                 +-------------+
                        |
                  ew_time counts
                        |
                        v
                 +-------------+
                 |  EW_YELLOW  |
                 +-------------+
                        |
                  3 clock counts
                        |
                        v
                 +-------------+
                 |  NS_GREEN   |
                 +-------------+
```

The green-state duration (`ns_time` or `ew_time`) is density-dependent and can be 5, 12, or 20 clock counts. The yellow-state duration is always fixed at 3 clock counts, independent of density.

## 8. Working Principle

### Step 1 — Reset

When `rst` is asserted, `state` is forced to `NS_GREEN` and `count` is forced to `0`. Because the design uses:

```verilog
always @(posedge clk or posedge rst)
```

`rst` appears directly in the sensitivity list alongside `posedge clk`, which makes this an **asynchronous reset** — it takes effect immediately when `rst` goes high, not only at the next clock edge.

### Step 2 — Determine North-South Timing

`ns_time` is continuously recalculated based on `north_density` and `south_density`, using the threshold logic described in Section 5.

### Step 3 — North-South Green

During `NS_GREEN`, `count` increments each clock cycle. Once `count` reaches `ns_time - 1`, the FSM resets `count` to `0` and moves to `NS_YELLOW` on the next clock edge — meaning the state is actually held for exactly `ns_time` clock cycles in total.

### Step 4 — North-South Yellow

`NS_YELLOW` uses the same pattern but against a fixed threshold (`count < 2`), so it's held for exactly 3 clock cycles before moving to `EW_GREEN`.

### Step 5 — East-West Green

`EW_GREEN` behaves the same way as `NS_GREEN`, but timed against `ew_time` instead.

### Step 6 — East-West Yellow

`EW_YELLOW` behaves the same way as `NS_YELLOW` — a fixed 3-clock-cycle hold — before returning to `NS_GREEN`.

### Step 7 — Repeat

The FSM loops back to `NS_GREEN`, where `ns_time` is re-evaluated against whatever the density inputs currently are, so the timing can change from one cycle to the next if the density values change.

## 9. Adaptive Behavior Example

This example follows the actual scenarios applied in `ATL_TB.v`:

**Scenario 1 — all densities low (`= 1`):** both North-South and East-West fall into the "otherwise" band, so both groups use **5 clock counts** of green time.

**Scenario 2 — `north = 7, south = 6, east = 1, west = 1`:** North-South has a density ≥ 5, so `ns_time = 20`. East-West stays low, so `ew_time = 5`.

**Scenario 3 — `north = 1, south = 1, east = 7, west = 6`:** now East-West has a density ≥ 5, so `ew_time = 20`, while North-South drops back to `ns_time = 5`.

**Scenario 4 — all densities `= 3`:** both groups land in the middle band (`>= 3` but `< 5`), so both use **12 clock counts**.

This sequence directly demonstrates the adaptive behavior — the green duration for each group changes as soon as the corresponding density inputs cross a threshold, without needing any change to the FSM structure itself.

## 10. Testbench

`ATL_TB.v` instantiates the controller as `dut` and connects it to all four density inputs, `clk`, `rst`, and the four light outputs.

**Clock generation:**

```verilog
always
begin
    #5 clk = ~clk;
end
```

This toggles `clk` every 5 ns, giving:

```text
Clock half-period = 5 ns
Clock period      = 10 ns
```

**Test sequence:**

```text
Initial:
  rst = 1
  north_density = south_density = east_density = west_density = 1

After 20 ns:
  rst = 0

After another 100 ns:
  north_density = 7, south_density = 6, east_density = 1, west_density = 1

After another 300 ns:
  north_density = 1, south_density = 1, east_density = 7, west_density = 6

After another 300 ns:
  north_density = south_density = east_density = west_density = 3

After another 300 ns:
  $finish is called, simulation ends
```

This covers a low-density case, a high North-South density case, a high East-West density case, and a medium-density case for both groups. The testbench doesn't include any assertions or automatic pass/fail checking — it's meant for observing the light outputs on the waveform as the density inputs change.

## 11. Simulation Results

![Adaptive Traffic Light Simulation](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/TRAFFIC-LIGHTS-USING-VERILOG/refs/heads/main/ATL_IMAGES/ATL_Timing.jpg)

From the waveform:

- `clk` toggles continuously at a fixed rate throughout, and `rst` is visible high briefly at the very start before being released, matching the testbench's reset pulse.
- `north_density`, `south_density`, `east_density`, and `west_density` step through the four test scenarios described above — visible in the waveform as `1`, then `7`/`6` on North/South, then `7`/`6` on East/West, then `3` on all four.
- `light_north` and `light_south` are shown cycling through the values `1`, `2`, and `4`, corresponding to `3'b001` (Green), `3'b010` (Yellow), and `3'b100` (Red).
- `light_east` and `light_west` show the same three values, but out of phase with North/South — while North/South show green (`1`), East/West show red (`4`), and vice versa, which matches the FSM only ever having one group active at a time.
- The North-South green segment visibly widens during the high-North-South-density scenario, and the East-West green segment visibly widens during the high-East-West-density scenario, compared to the low- and medium-density segments — this is consistent with the `ns_time`/`ew_time` values of 5, 12, and 20 clock counts changing the duration of each group's green phase.

## 12. RTL / Elaborated Schematic

```markdown
![Adaptive Traffic Light RTL Schematic](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/TRAFFIC-LIGHTS-USING-VERILOG/refs/heads/main/ATL_IMAGES/ATL_schematic.jpg)
```

**Note on the schematic file:** the file uploaded as `ATL_schematic.jpg` for this section is actually an identical copy of the same simulation waveform used in Section 11 — it is not an RTL/elaborated schematic view. I can't describe the specific muxes, registers, or nets from it, since it doesn't show that view. You'll want to open `Advanced_tl.v` in Vivado, run **Open Elaborated Design**, and capture the actual schematic screenshot to replace this file before publishing.

In general, based on the actual RTL code, an elaborated schematic of this design would be expected to show:

- Density-comparison logic for both `ns_time` and `ew_time`, likely represented as comparator and multiplexer chains selecting between 5, 12, and 20
- A 2-bit state register (`state_reg`) and a separate counter register (`count_reg`) for timing each phase
- Combinational logic implementing the `case (state)` next-state and yellow/green duration checks
- Combinational output logic driving the four `light_*` outputs based on the current state
- Four separate output paths for `light_north`, `light_south`, `light_east`, and `light_west`

This description is based on the code structure, not a confirmed reading of an actual schematic — replace it with real observations once the correct screenshot is available.

## 13. Verilog Design Structure

`Advanced_tl.v` is organized into four separate `always` blocks:

### Density calculation

Two `always @(*)` blocks compute `ns_time` and `ew_time` combinationally, each using its own threshold comparison against the relevant pair of density inputs, as described in Section 5.

### Sequential FSM and counter

The `always @(posedge clk or posedge rst)` block holds the actual state machine. It handles the asynchronous reset, and for each state, checks `count` against the appropriate duration (`ns_time`, `ew_time`, or the fixed value `2` for yellow phases) to decide whether to keep incrementing `count` or move to the next state and reset `count` to `0`.

### Output logic

A separate `always @(*)` block sets all four light outputs to `RED` by default, then overrides the relevant pair to `GREEN` or `YELLOW` based on the current `state`. Because this block only depends on `state`, the outputs update combinationally as soon as the state changes.

## 14. Timing Behavior

```text
Low density    → 5 clock counts
Medium density → 12 clock counts
High density   → 20 clock counts
Yellow         → 3 clock counts
```

These are clock-cycle counts, not seconds. Using the testbench's 10 ns clock period, these correspond to the following simulated durations:

```text
5 counts  ≈ 50 ns
12 counts ≈ 120 ns
20 counts ≈ 200 ns
3 counts  ≈ 30 ns
```

These durations are only valid for the 10 ns clock period used in this specific testbench — they would scale differently under a different clock frequency, and none of them represent real-world seconds.

## 15. Tools and Technologies

- Verilog HDL
- Xilinx Vivado
- RTL Elaboration
- Behavioral Simulation
- Verilog Testbench

No FPGA hardware implementation was performed — this project is demonstrated through RTL elaboration and behavioral simulation only.

## 16. Project Files

| File | Description |
|------|--------------|
| `Advanced_tl.v` | Density-based adaptive traffic-light controller |
| `ATL_TB.v` | Testbench for adaptive traffic-light simulation |
| `ATL_IMAGES/ATL_schematic.jpg` | Intended to hold the Vivado elaborated RTL schematic (currently a duplicate of the timing waveform — see Section 12) |
| `ATL_IMAGES/ATL_Timing.jpg` | Behavioral simulation waveform |
| `README.md` | Project documentation |

## 17. How to Run the Project in Vivado

1. Open Xilinx Vivado.
2. Create a new RTL project.
3. Add `Advanced_tl.v` as the design source.
4. Add `ATL_TB.v` as the simulation source.
5. Set `traffic_light_density_tb` as the simulation top module if Vivado doesn't select it automatically.
6. Run **Behavioral Simulation** from the Flow Navigator.
7. Add the four density inputs (`north_density`, `south_density`, `east_density`, `west_density`) to the waveform.
8. Add the four traffic-light outputs (`light_north`, `light_south`, `light_east`, `light_west`) to the waveform.
9. Adjust the simulation time scale as needed to clearly see how the green-phase width changes between the low, medium, and high density scenarios.

## 18. Learning Outcomes

- Designing an FSM with multiple states in Verilog
- Using a counter register to time each FSM state
- Implementing combinational density-comparison logic to drive a decision (`ns_time`, `ew_time`)
- Feeding a dynamically computed value into a sequential timing comparison, rather than a fixed constant
- Working with multiple related input signals (four density inputs, grouped into two decision paths)
- Designing safe green → yellow → opposite-green → yellow transitions
- Writing a Verilog testbench that exercises several distinct input scenarios
- Running behavioral simulation in Vivado and reading a multi-signal waveform
- Understanding RTL elaboration and being able to tell when a screenshot doesn't actually match the design it's supposed to represent

## 19. Possible Future Improvements

These are potential extensions, not part of the current implementation:

- Interfacing the density inputs with actual vehicle sensors instead of manually applied test values
- Using a parameterized clock divider so the timing values correspond to real-world seconds
- Adding pedestrian crossing control
- Adding emergency-vehicle priority handling
- Making the timing thresholds and durations configurable instead of hardcoded
- Adding dedicated vehicle-count sensors
- FPGA board implementation and hardware testing
- Adding seven-segment countdown displays for the active phase
- Adding fairness logic so one direction group can't be starved indefinitely by consistently low density

## 20. Limitations

- Density values are supplied directly as 3-bit digital inputs — there's no actual sensor or detection hardware behind them in this project.
- The current design doesn't interface with any physical traffic sensors, cameras, or IoT devices.
- All timing values are expressed and verified in clock counts, not real-world seconds.
- The testbench uses a simplified 10 ns clock period purely for simulation convenience.
- The controller only alternates between two fixed direction groups (North-South and East-West) — it doesn't control each of the four directions fully independently.

## 21. Conclusion

This project extends a conventional FSM-based traffic-light controller by making the green-light duration for each direction group depend on digital traffic-density inputs, rather than using one fixed value for every cycle. Building it required combining a counter-timed FSM with combinational threshold logic that recalculates the green duration on the fly, and verifying that behavior across several density scenarios in simulation. It's a practical example of how adaptive decision-making can be layered on top of a standard sequential control structure in Verilog.
