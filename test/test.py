# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # VGA line timing: hsync (uo_out[7], active low) is a 96-cycle pulse every 800 cycles.
    def hsync():
        return (int(dut.uo_out.value) >> 7) & 1

    async def cycles_until(level):
        cycles = 0
        while hsync() != level:
            await ClockCycles(dut.clk, 1)
            cycles += 1
            assert cycles <= 1000, "hsync stuck"
        return cycles

    await cycles_until(1)
    await cycles_until(0)  # A pulse starts.
    pulse = await cycles_until(1)
    rest = await cycles_until(0)
    assert pulse == 96, f"hsync pulse of {pulse} cycles"
    assert pulse + rest == 800, f"line of {pulse + rest} cycles"
    assert dut.uio_oe.value == 0
