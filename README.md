# Adaptive Traffic Light Density Controller Using Verilog HDL

This project implements a traffic light controller in Verilog HDL that adjusts its green-light duration based on real-time traffic density at a four-way intersection, instead of running on a fixed timer. It was designed and verified using RTL modeling and behavioral simulation.

---

## 1. Project Overview

A standard traffic light controller usually cycles through fixed green/yellow/red durations regardless of how much traffic is actually present. This project changes that by making the green-light duration for each direction depend on a 3-bit density value supplied for that direction.

The intersection is modeled as two traffic axes:

* **North–South (NS)** axis
* **East–West (EW)** axis

Only one axis is given green at a time. The controller cycles through four phases:

```text
NS_GREEN → NS_YELLOW → EW_GREEN → EW_YELLOW → NS_GREEN → ...
```

The duration of each GREEN phase is not fixed — it is computed combinationally from the density inputs of the corresponding axis before the FSM enters that phase.

---

## 2. Project Objective

This project was built to get hands-on practice with:

* Finite state machine (FSM) design in Verilog
* Combinational logic for decision-making (density-to-time mapping)
* Synchronous sequential logic driven by `posedge clk`
* Asynchronous reset handling
* Multi-signal I/O design (four density inputs, four light outputs)
* Writing a self-checking-free stimulus testbench
* Reading behavioral simulation waveforms in Vivado

---

## 3. Features

* Four-way traffic light control: North, South, East, West
* 3-bit traffic density input per direction (`0`–`7`)
* Adaptive green-light duration based on density thresholds
* Fixed, short yellow phase between green phases
* Single shared FSM alternates between the NS axis and the EW axis
* Encoded light outputs (`RED`, `YELLOW`, `GREEN`) per direction
* Asynchronous reset that returns the FSM to a known state
* Default `case` recovery state to avoid an undefined FSM state

---

## 4. Inputs and Outputs

| Signal           | Direction | Width  | Description                                   |
|-------------------|-----------|-------:|------------------------------------------------|
| `clk`             | Input     | 1 bit  | System clock                                    |
| `rst`             | Input     | 1 bit  | Asynchronous reset                              |
| `north_density`   | Input     | 3 bits | Traffic density on the North approach (0–7)     |
| `south_density`   | Input     | 3 bits | Traffic density on the South approach (0–7)     |
| `east_density`    | Input     | 3 bits | Traffic density on the East approach (0–7)      |
| `west_density`    | Input     | 3 bits | Traffic density on the West approach (0–7)      |
| `light_north`     | Output    | 3 bits | Light state for the North approach              |
| `light_south`     | Output    | 3 bits | Light state for the South approach              |
| `light_east`      | Output    | 3 bits | Light state for the East approach                |
| `light_west`      | Output    | 3 bits | Light state for the West approach                |

The density inputs are 3 bits wide, which is enough to represent density levels from 0 to 7 — sufficient for the three threshold bands the design actually checks (`< 3`, `3–4`, `≥ 5`). The light outputs are 3 bits wide because each light is encoded as a one-hot pattern rather than a 2-bit binary code:

```verilog
parameter RED    = 3'b100;
parameter YELLOW = 3'b010;
parameter GREEN  = 3'b001;
```

---

## 5. Internal Registers

```verilog
reg [1:0] state;   // current FSM phase
reg [4:0] count;   // cycle counter within the current phase
reg [4:0] ns_time; // computed green duration for the NS axis
reg [4:0] ew_time; // computed green duration for the EW axis
```

`state` holds one of four phases:

```verilog
parameter NS_GREEN  = 2'b00;
parameter NS_YELLOW = 2'b01;
parameter EW_GREEN  = 2'b10;
parameter EW_YELLOW = 2'b11;
```

`count` is a 5-bit counter that tracks how many clock cycles the FSM has spent in the current phase. `ns_time` and `ew_time` are computed continuously (combinationally) from the density inputs, so the correct duration is already available whenever the FSM enters a green phase.

---

## 6. Density-to-Time Mapping

Two independent combinational blocks compute the green duration for each axis:

```verilog
if ((north_density >= 5) || (south_density >= 5))
    ns_time = 20;
else if ((north_density >= 3) || (south_density >= 3))
    ns_time = 12;
else
    ns_time = 5;
```

The same logic (using `east_density` / `west_density`) computes `ew_time`. This means:

| Density condition (either direction on the axis) | Green duration (clock cycles) |
|----------------------------------------------------|:------------------------------:|
| `density >= 5`                                      | 20                             |
| `3 <= density < 5`                                  | 12                              |
| `density < 3`                                       | 5                                |

Heavier traffic on an axis results in a longer green phase for that axis.

---

## 7. Working Principle

### Step 1 — Clock and Reset

The FSM is sensitive to both the rising edge of `clk` and the rising edge of `rst`:

```verilog
always @(posedge clk or posedge rst)
```

This makes the reset **asynchronous** — it forces `state` back to `NS_GREEN` and `count` to `0` immediately, without waiting for a clock edge.

### Step 2 — NS_GREEN

While in `NS_GREEN`, `count` increments every clock cycle until it reaches `ns_time - 1`. Once that happens, `count` resets to `0` and `state` moves to `NS_YELLOW`. In total, the FSM spends `ns_time` clock cycles in this phase.

### Step 3 — NS_YELLOW

`count` increments while it is less than `2`. Once `count` reaches `2`, the FSM moves to `EW_GREEN`. This phase therefore always lasts a fixed 3 clock cycles (`count` = 0, 1, 2), regardless of density.

### Step 4 — EW_GREEN

Same behavior as `NS_GREEN`, but using `ew_time` and moving to `EW_YELLOW` afterward.

### Step 5 — EW_YELLOW

Same fixed 3-cycle behavior as `NS_YELLOW`, after which the FSM returns to `NS_GREEN`, completing the cycle.

### Step 6 — Light Output Decoding

A separate combinational block decodes `state` into the four light outputs. All four outputs default to `RED`, and then the active axis is overridden to `GREEN` or `YELLOW` depending on the current phase:

```verilog
light_north = RED;
light_south = RED;
light_east  = RED;
light_west  = RED;

case (state)
    NS_GREEN:  begin light_north = GREEN;  light_south = GREEN;  end
    NS_YELLOW: begin light_north = YELLOW; light_south = YELLOW; end
    EW_GREEN:  begin light_east  = GREEN;  light_west  = GREEN;  end
    EW_YELLOW: begin light_east  = YELLOW; light_west  = YELLOW; end
endcase
```

This guarantees that the two axes are never both green at the same time.

---

## 8. FSM Diagram

```text
                 rst
                  │
                  v
            ┌───────────┐
      ┌────>│ NS_GREEN  │────┐
      │      └───────────┘    │ count == ns_time-1
      │                       v
      │               ┌────────────┐
      │               │ NS_YELLOW  │
      │               └────────────┘
      │                       │ count == 2
      │                       v
┌────────────┐        ┌────────────┐
│ EW_YELLOW  │<───────│  EW_GREEN  │
└────────────┘ count  └────────────┘
      │        == ew_time-1     ^
      └─────────────────────────┘
              count == 2
```

---

## 9. Verilog Implementation

`Advanced_tl.v` is organized into four always blocks:

* **`ns_time` combinational block** — evaluates North/South density and sets the NS green duration.
* **`ew_time` combinational block** — evaluates East/West density and sets the EW green duration.
* **FSM sequential block** (`posedge clk or posedge rst`) — advances `count` and `state` on every clock edge, or resets on `rst`. Includes a `default` case that returns to `NS_GREEN` as a safety net.
* **Output decode block** — a combinational `always @(*)` block that converts `state` into the four light outputs.

The module itself, `traffic_light_density`, has no internal instantiation of other modules — it is a single self-contained FSM with two supporting combinational functions.

---

## 10. Testbench

`ATL_TB.v` defines `traffic_light_density_tb`, which instantiates the design under test (`dut`) and drives it with the following stimulus:

**Clock generation:**

```verilog
always begin
    #5 clk = ~clk;
end
```

This toggles `clk` every 5 ns, giving a clock period of 10 ns.

**Stimulus sequence:**

```text
t = 0 ns    : rst = 1, all densities = 1
t = 20 ns   : rst = 0 (FSM starts running)
t = 120 ns  : north_density = 7, south_density = 6, east_density = 1, west_density = 1
t = 420 ns  : north_density = 1, south_density = 1, east_density = 7, west_density = 6
t = 720 ns  : all densities = 3
t = 1020 ns : $finish
```

This exercises three scenarios: heavy NS traffic, heavy EW traffic, and moderate/equal traffic on all four approaches. The testbench does not include any self-checking assertions — it is a stimulus-only testbench meant to be observed on the simulator waveform.

---

## 11. Simulation Results

![Traffic Light Density Simulation Waveform](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/TRAFFIC-LIGHTS-USING-VERILOG/refs/heads/main/ATL_IMAGES/ATL_Timing.jpg)

From the waveform:

* `clk` toggles continuously at a 10 ns period.
* `rst` is asserted briefly at the start and then released, after which the FSM begins cycling.
* When `north_density`/`south_density` are raised to `7`/`6`, `light_north` and `light_south` hold the `GREEN` (`1`) encoding for a visibly longer interval before transitioning through `YELLOW` (`2`) — reflecting the `ns_time = 20` case.
* When the density is later shifted to `east_density`/`west_density` (`7`/`6`), the same widened green interval is instead visible on `light_east` and `light_west`.
* During the final segment, with all densities set to `3`, the green intervals on both axes are noticeably shorter and closer to each other, corresponding to the `ns_time = ew_time = 12` case.
* `light_north`/`light_south` and `light_east`/`light_west` are never green at the same time, confirming the mutual-exclusion behavior of the FSM.

---

## 12. RTL / Elaborated Schematic

![Traffic Light Density RTL Schematic](https://raw.githubusercontent.com/VASUDEVARAO-SANKARAPU/TRAFFIC-LIGHTS-USING-VERILOG/refs/heads/main/ATL_IMAGES/atl%20sch.jpeg)

This is the RTL schematic elaborated by Vivado from `Advanced_tl.v`. It represents the hardware structure inferred from the Verilog code — not a physical chip layout. In this schematic, the major elements visible are:

* The `clk` and `rst` inputs feeding the sequential logic
* The four density input buses (`north_density`, `south_density`, `east_density`, `west_density`)
* The `state` and `count` registers that hold the FSM's current phase and cycle count
* Combinational logic blocks computing `ns_time` and `ew_time` from the density inputs
* Combinational logic decoding `state` into the four light outputs
* Feedback paths from the state/count registers back into the next-state and count logic

---

## 13. Tools and Technologies

* Verilog HDL
* Xilinx Vivado
* RTL / behavioral simulation
* Finite state machine (FSM) design

---

## 14. Project Files

| File                             | Description                                        |
|-----------------------------------|-----------------------------------------------------|
| `Advanced_tl.v`                   | Main traffic light density controller design         |
| `ATL_TB.v`                        | Testbench for behavioral simulation                   |
| `ATL_IMAGES/atl sch.jpeg`         | Vivado RTL elaborated schematic                       |
| `ATL_IMAGES/ATL_Timing.jpg`       | Behavioral simulation waveform                        |
| `README.md`                       | Project documentation                                  |

---

## 15. How to Run the Project in Vivado

1. Open Xilinx Vivado and create a new RTL project.
2. Add `Advanced_tl.v` as a design source.
3. Add `ATL_TB.v` as a simulation source.
4. Set `traffic_light_density_tb` as the simulation top module.
5. Run **Behavioral Simulation**.
6. Add `clk`, `rst`, `north_density`, `south_density`, `east_density`, `west_density`, `light_north`, `light_south`, `light_east`, and `light_west` to the waveform viewer if they are not already shown.
7. Run the simulation for at least 1000 ns and inspect how the light outputs respond to the density changes.

---

## 16. Important Note About Simulation Timing

The green-light durations in this design (5, 12, and 20) are expressed in **clock cycles**, not seconds. With the testbench's 10 ns clock period, a duration of 20 cycles corresponds to 200 ns of simulation time — not 20 real-world seconds. For a real deployment, these cycle counts would need to be derived from the actual system clock frequency so that each phase corresponds to a real-time duration (e.g., a few seconds), and the density thresholds would need to be tuned using real sensor data rather than testbench-assigned values.

---

## 17. Learning Outcomes

Working on this project helped reinforce:

* Designing a finite state machine in Verilog using a `case` statement
* Separating combinational decision logic from sequential state-transition logic
* Handling synchronous behavior with an asynchronous reset
* Encoding multi-bit output signals (one-hot light encoding)
* Writing a stimulus-driven testbench without built-in assertions
* Reading and interpreting Vivado behavioral simulation waveforms
* Thinking about how a simulation-scale design would need to change for real hardware timing

---

## 18. Possible Future Improvements

* Deriving green-phase durations from a real clock frequency for true real-time operation
* Adding more density levels or a continuous/analog density input
* Pedestrian crossing signal integration
* Emergency vehicle priority override
* Seven-segment countdown display for each phase
* Interfacing with real traffic sensors instead of testbench-driven values
* FPGA board implementation and hardware validation

---

## 19. Conclusion

This project demonstrates a traffic light controller whose green-phase duration adapts to traffic density instead of running on a fixed timer. It combines simple combinational threshold logic with a four-state Verilog FSM, and its behavior was verified through a stimulus-driven testbench and Vivado behavioral simulation. The next step toward a realistic deployment would be scaling the cycle counts to actual real-time durations and integrating real traffic sensor data.
