# Variable Latency Iterative Multiplier

A 32-bit signed iterative multiplier in Verilog. It uses shift-and-add, but instead of consuming one multiplier bit per cycle, it skips runs of zeros. The latency therefore depends on the multiplier operand, and the multiplication stops as soon as the remaining bits are zero.

Signed inputs are converted to magnitudes before the core runs, and the sign is applied to the result at the end. The output is the low 32 bits of the product.

## Valid/Ready Interface

Because the latency varies, the multiplier uses a valid/ready handshake on both sides.

- **Input:** `istream_msg` carries `{a, b}` as 64 bits. An operand is accepted when `istream_val` and `istream_rdy` are both high.
- **Output:** `ostream_msg` carries the 32-bit product. It is held until `ostream_val` and `ostream_rdy` are both high.

The surrounding logic never needs to know how many cycles a multiplication takes.

## FSM

The control unit has three states.

| State | Name | Behavior |
| ----- | ---- | -------- |
| `s1`  | Idle | Wait for `istream_val`, then load `a` and `b` |
| `s2`  | Calc | If `b[0]` is set, add `a` to the result. Shift `b` right and `a` left by `sparse_count` |
| `s3`  | Done | Present the product, return to idle once `ostream_rdy` is high |

The calculation ends when `b` becomes zero or 32 bit positions have been consumed. `sparse_counter.v` provides `sparse_count`, the index of the lowest set bit in `b` (minimum 1). The `sparse_on` parameter in `control_unit.v` turns skipping off for a plain one-bit-per-cycle multiplier.

## Repository Structure

```
docs/              reference images
imul_main.v        top level, signed handling
control_unit.v     FSM and handshake
datapath.v         registers, shifters, adder
sparse_counter.v   finds the next set bit of b
testbench.v        self-checking testbench
README.md
```

## Simulation

Requires [Icarus Verilog](https://github.com/steveicarus/iverilog).

```
iverilog -g2012 -o sim testbench.v imul_main.v control_unit.v datapath.v sparse_counter.v
vvp sim
```

The testbench runs directed cases and prints `pass` or `FAIL` for each, then `ALL PASSED` at the end.
