# SHA-256 / Bitcoin Double-Hash Hardware Accelerator
 
A SystemVerilog implementation of SHA-256 and Bitcoin-style double-SHA256 hashing, built as an FPGA hardware design rather than software. The project's real focus isn't just "does it produce the right hash" but how to restructure a sequential cryptographic algorithm into hardware that uses less area and finishes in fewer clock cycles, then proving that with real synthesis and timing results instead of just a passing simulation.
 
Built solo as the final project for UCSD's ECE 111 (Digital Logic and FPGA design).
 
## What it actually does
 
There are two independent RTL modules here, each solving a different problem:
 
- **`simplified_sha256.sv`** takes a message and produces its 256-bit SHA-256 digest. This is the core algorithm on its own, no mining logic involved.
- **`bitcoin_hash.sv`** is the harder problem: it computes Bitcoin's proof-of-work hash, which is SHA-256 applied twice in a row to a block header, and it does this for 16 different nonce values at once. This mirrors what a real mining ASIC does at a small scale: fix everything about the block except the nonce, and search across nonce values as fast as possible.
Neither module talks over a standard bus protocol like AXI or APB. The interface is a simple synchronous memory-style handshake (`start`, `reset`, `done`, plus `mem_we` / `mem_addr` / `mem_write_data` / `mem_read_data`), which keeps the design focused on the compute datapath rather than interconnect.
 
## The interesting part: how it's optimized
 
A naive SHA-256 implementation precomputes all 64 message schedule words for a block up front and stores them in a 64-entry array before running any compression rounds. That's simple to write but wastes a lot of registers, since only 16 words are ever needed at a time.
 
This design instead computes each message schedule word on the fly using a 16-entry shift register:
 
- For the first 16 rounds, the compression function consumes the original message words directly out of the shift register.
- From round 17 onward, a new word is computed each cycle using SHA-256's standard word-expansion formula, and the register shifts, dropping the oldest word and appending the new one.
- The design never holds more than 16 words of schedule state at once, instead of 64.
That register savings is what makes the Bitcoin module feasible at all. Bitcoin's proof-of-work has three logical phases:
 
1. **Phase 1** processes the first 512-bit block of the header, which is identical for every nonce, so it only needs to be computed once, not 16 times.
2. **Phase 2** processes the second block, which contains the nonce, starting from phase 1's hash state.
3. **Phase 3** re-hashes phase 2's 256-bit output as a fresh message, since Bitcoin's proof-of-work is a hash of a hash.
Phases 2 and 3 have to run once per nonce, since each nonce produces a different result. A fully serial design would run one SHA-256 engine through phases 2 and 3 for each of the 16 nonces in sequence. Instead, this design replicates the compression logic and runs 8 independent SHA-256 engines in parallel, each with its own working registers, its own w[16] shift register, and its own running hash accumulator. A full 16-way replication doesn't fit on the target device, so the design runs the 8 engines across two waves: nonces 0 through 7 first, then the same 8 engines get reset and reused for nonces 8 through 15. Since phase 1's result is nonce-independent, both waves just reload it rather than recomputing it.
 
## Verification
 
Correctness was verified against self-checking testbenches provided by the course (not self-authored) in ModelSim/Questa. Each testbench feeds in a fixed reference input and automatically compares every computed hash word against a known-correct value, printing a pass/fail for each word and a final summary.
 
- SHA-256: all 8 output words matched the reference digest.
- Bitcoin: all 16 nonces' final hash values (H0[0] through H0[15]) matched their reference values.
This is directed, fixed-vector verification, not randomized or coverage-driven testing. No UVM, no cocotb, no functional coverage metrics were collected. That's the honest scope of it: enough to prove the RTL is bit-accurate against a known-good reference, not a production-grade verification environment.
 
## Synthesis and timing results
 
Both modules were synthesized in Quartus Prime 21.1.1 targeting an Arria II GX FPGA (EP2AGX45DF29I5), with timing closed at the Slow 900mV 100C corner.
 
| Module | Cycles per operation | Combinational ALUTs | Registers | Fmax |
|---|---|---|---|---|
| SHA-256 (single hash) | 167 | 1,972 (5% of device) | 1,750 (5%) | 144.26 MHz |
| Bitcoin (all 16 nonces) | 375 | 12,314 (34%) | 9,866 (27%) | 127.05 MHz |
 
Some context on what those numbers mean:
 
- The course's grading thresholds for full optimization credit were 200 cycles for SHA-256 and 600 cycles for Bitcoin. Both modules land comfortably under those bars.
- A fully serial Bitcoin implementation, running one engine through all 16 nonces one after another, would take roughly 8 times as many cycles as the 8-way parallel version here, since 8 nonces' worth of phase 2/3 work now happens simultaneously instead of sequentially.
- Neither design uses any block memory (0 bits used in both cases) or inferred latches, so all resource usage is pure combinational and register logic doing the actual hashing.
## Tools and skills
 
- **SystemVerilog** for all RTL, written as synthesizable, synchronous logic (no behavioral shortcuts that wouldn't map to real hardware).
- **Quartus Prime 21.1.1** (Analysis and Synthesis, Fitter, TimeQuest Timing Analyzer) for synthesis, place-and-route, and static timing closure on a real FPGA target.
- **ModelSim/Questa** for RTL simulation and waveform-level debugging.
- Architectural skills exercised: FSM design across multiple algorithmic phases, register-efficient datapath design (the w[16] shift register), and resource-constrained parallel replication (deciding on 8-way plus two waves instead of a 16-way design that wouldn't fit).
## Notes and limitations
 
- This implements a simplified version of Bitcoin mining: the block header contents are fixed and the search space is exactly 16 nonce values, rather than an open-ended search against a difficulty target.
- The testbenches were provided as part of the course, not written from scratch as part of this project.
- No power analysis was run; only area and Fmax are reported.
 
