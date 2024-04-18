/* Top-level verilog definitions for step/dir stepper motor pulse scheduler
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_koconnor_kstep (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Wires used for spi commands
    wire spi_cs, spi_mosi, spi_miso, spi_sclk;
    assign spi_cs = uio_in[0];
    assign uio_oe[0] = 0;
    assign spi_mosi = uio_in[1];
    assign uio_oe[1] = 0;
    assign uio_out[2] = spi_miso;
    assign uio_oe[2] = 1;
    assign spi_sclk = uio_in[3];
    assign uio_oe[3] = 0;

    // Wires used for command signals
    wire signal_irq, signal_shutdown;
    assign uio_out[4] = signal_irq;
    assign uio_oe[4] = 1;
    assign signal_shutdown = uio_in[5];
    assign uio_oe[5] = 0;

    // Assign remaining uio wires to zero.
    assign uio_out[1:0] = 0, uio_out[3] = 0, uio_out[5] = 0, uio_out[7:6] = 0;
    assign uio_oe[7:6] = 0;

    // Temporarily assign all output wires
    assign spi_miso=0, signal_irq=0;
    assign uo_out = ui_in + uio_in;

endmodule
