# AHB-to-APB Bridge using Verilog HDL

A Verilog HDL implementation of an **AMBA AHB-to-APB Bridge** that connects a high-performance AHB-Lite interface to a low-power APB peripheral interface.

The bridge uses a Finite State Machine (FSM) to control the transfer between AHB and APB protocols. The design is verified using a Verilog testbench with write, read, wait-state, and peripheral-error test scenarios.

## Project Overview

The AHB-to-APB Bridge acts as an interface between:

- **AHB-Lite:** Advanced High-performance Bus interface.
- **APB:** Advanced Peripheral Bus interface.

It converts an AHB transfer request into the corresponding APB setup and access phases.

## Features

- AHB-Lite slave-side interface.
- APB master-side interface.
- Three-state FSM architecture.
- Read and write transaction handling.
- APB setup and access phase control.
- Peripheral wait-state handling through `PREADY`.
- Peripheral error response handling through `PSLVERR`.
- Address, write-data, and control signal registers.
- Asynchronous active-low reset.
- Verilog testbench-based functional verification.

## Architecture

The bridge consists of three main FSM states:

| State | Description |
|---|---|
| IDLE | Waits for a valid AHB transfer request. |
| SETUP | Starts the APB setup phase and captures write data. |
| ACCESS | Performs the APB access phase and waits for peripheral readiness. |

### Transfer sequence

1. The AHB master provides the address, transfer type, and read/write control.
2. The bridge captures the AHB address and write control.
3. The bridge activates APB setup by asserting `PSEL`.
4. The bridge enters APB access by asserting `PENABLE`.
5. The bridge waits until `PREADY` is asserted.
6. For read transactions, the bridge transfers `PRDATA` to `HRDATA`.
7. The bridge reports peripheral errors through `HRESP`.

## Interface Signals

### AHB-Lite Interface

| Signal | Width | Description |
|---|---:|---|
| `HCLK` | 1 | AHB clock |
| `HRESETn` | 1 | Active-low reset |
| `HADDR` | 32 | Address input |
| `HTRANS` | 2 | Transfer type |
| `HWRITE` | 1 | Read/write control |
| `HSEL` | 1 | Slave select |
| `HREADY` | 1 | AHB ready input |
| `HWDATA` | 32 | Write data |
| `HRDATA` | 32 | Read data output |
| `HREADYOUT` | 1 | Bridge ready output |
| `HRESP` | 1 | Response/error output |

### APB Interface

| Signal | Width | Description |
|---|---:|---|
| `PADDR` | 32 | APB address |
| `PWRITE` | 1 | APB read/write control |
| `PSEL` | 1 | APB peripheral select |
| `PENABLE` | 1 | APB access enable |
| `PWDATA` | 32 | APB write data |
| `PRDATA` | 32 | APB read data input |
| `PREADY` | 1 | Peripheral ready input |
| `PSLVERR` | 1 | Peripheral error input |

## FSM Operation

### 1. IDLE State

- Waits for `HSEL`, `HREADY`, and a valid AHB transfer (`HTRANS[1]`).
- Captures the address and read/write control.
- Moves to SETUP when a valid transfer is detected.

### 2. SETUP State

- Asserts `PSEL`.
- Keeps `PENABLE` low.
- Captures write data for write transactions.
- Moves to ACCESS.

### 3. ACCESS State

- Asserts both `PSEL` and `PENABLE`.
- Waits for `PREADY`.
- Transfers read data and reports `PSLVERR` when the peripheral completes the transaction.
- Returns to IDLE when the transfer completes.

## Project Structure

```text
AHB_to_APB_Bridge/
│
├── ahb_to_apb_bridge.v       # Main bridge RTL design
├── tb_ahb_to_apb_bridge.v    # Verilog testbench
├── ahb_apb.vcd               # Simulation waveform
├── ahb_apb_test              # Compiled simulation executable
├── README.md                 # Project documentation
│
└── Screenshots/
    ├── Screenshot 1
    └── Screenshot 2
```

## Tools Used

- **HDL:** Verilog
- **Simulator:** Icarus Verilog
- **Waveform Viewer:** GTKWave
- **Version Control:** Git and GitHub

## Simulation Instructions

### Step 1: Compile the RTL and testbench

```bash
iverilog -g2012 -Wall -o ahb_apb_test ahb_to_apb_bridge.v tb_ahb_to_apb_bridge.v
```

### Step 2: Run the simulation

```bash
vvp ahb_apb_test
```

### Step 3: View the waveform

```bash
gtkwave ahb_apb.vcd
```

## Verification Scenarios

The testbench includes the following scenarios:

| Test | Description |
|---|---|
| Test 1 | AHB-to-APB write transaction |
| Test 2 | AHB-to-APB read transaction |
| Test 3 | APB peripheral error response |
| Test 4 | APB wait-state handling during write |

The testbench checks APB setup/access phases, write address and data, read data, ready response, and peripheral error response.

### Recorded Simulation Result

The previously recorded simulation output was:

```text
AHB TO APB BRIDGE TEST STARTED
WRITE TRANSACTION COMPLETED
READ TRANSACTION COMPLETED
PASS: ERROR RESPONSE
ALL AHB APB TESTS PASSED
```

This is the testbench-reported result for the supplied simulation. It does not establish full AMBA protocol compliance or hardware timing closure.

## Learning Outcomes

- Understanding AMBA AHB-Lite and APB interfaces.
- FSM-based RTL design.
- Bus protocol conversion.
- Read and write transaction sequencing.
- Peripheral wait-state handling.
- Error response handling.
- Verilog testbench development.
- RTL simulation and waveform debugging.

## Author

**Thariq**

GitHub: [Thariq006](https://github.com/Thariq006)

## Repository

[AHB-to-APB Bridge – Verilog HDL](https://github.com/Thariq006/AHB_to_APB_Bridge)
