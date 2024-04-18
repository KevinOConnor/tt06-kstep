# Cocotb test cases for kstep
#
# Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import cocotbext.spi


@cocotb.test()
async def test_kstep(dut):
    dut._log.info("Start")

    # Create spi device
    spi_bus = cocotbext.spi.SpiBus.from_entity(dut, prefix="spi")
    spi_config = cocotbext.spi.SpiConfig(sclk_freq=1000000)
    spi = cocotbext.spi.SpiMaster(spi_bus, spi_config)

    # Create clock
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.spi_cs.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Begin tests
    dut._log.info("Read clock test")
    await spi.write([0x70, 0x00, 0x00, 0x00, 0x00], burst=True)
    read_bytes = await spi.read()
    assert list(read_bytes[1:]) == [0x00, 0x00, 0x01, 0xab]
    await ClockCycles(dut.clk, 10)

    dut._log.info("Write clock test")
    await spi.write([0xf0, 0x80, 0xab, 0xcd, 0x01], burst=True)
    read_bytes = await spi.read()
    await ClockCycles(dut.clk, 10)
    await spi.write([0x70, 0x00, 0x00, 0x00, 0x00], burst=True)
    read_bytes = await spi.read()
    assert list(read_bytes[1:]) == [0x80, 0xab, 0xce, 0xfd]
    await ClockCycles(dut.clk, 10)
