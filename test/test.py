# Cocotb test cases for kstep
#
# Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import cocotbext.spi

class kstep_spi:
    def __init__(self, dut):
        self.dut = dut
        spi_bus = cocotbext.spi.SpiBus.from_entity(dut, prefix="spi")
        spi_config = cocotbext.spi.SpiConfig(sclk_freq=1000000)
        self.spi = cocotbext.spi.SpiMaster(spi_bus, spi_config)
    async def send(self, is_write, addr, val):
        v = [(is_write << 7) | (addr & 0x7f), (val >> 24) & 0xff,
             (val >> 16) & 0xff, (val >> 8) & 0xff, val & 0xff]
        await self.spi.write(v, burst=True)
        r = await self.spi.read()
        await ClockCycles(self.dut.clk, 10)
        return (r[1] << 24) | (r[2] << 16) | (r[3] << 8) | r[4]
    async def write(self, addr, val):
        await self.send(True, addr, val)
    async def read(self, addr):
        return await self.send(False, addr, 0)

@cocotb.test()
async def test_kstep(dut):
    dut._log.info("Start")

    # Create spi device
    spi = kstep_spi(dut)

    # Create clock
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.signal_shutdown.value = 0
    dut.spi_cs.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Begin tests
    dut._log.info("Read clock test")
    rv = await spi.read(0x70)
    assert rv == 0x1ab

    dut._log.info("Write clock test")
    await spi.write(0x70, 0x80abcd01)
    rv = await spi.read(0x70)
    assert rv == 0x80abcefd

    dut._log.info("Write pin polarity test")
    assert dut.uo_out[2].value == 0
    await spi.write(0x10, 0x04)
    assert dut.uo_out[2].value == 1

    dut._log.info("Step test")
    await spi.write(0x12, 8) # pulse duration
    await spi.write(0x70, 0xffffc000) # clear clock
    await spi.write(0x21, 100) # interval
    await spi.write(0x20, (20 << 16) | 5) # count, add
    await spi.write(0x22, 1) # dir
    await spi.write(0x21, 500) # interval
    await spi.write(0x20, (20 << 16) | (-15 & 0xffff)) # count, add
    await ClockCycles(dut.clk, 25000)
