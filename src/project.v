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

    // SPI to wishbone command handling
    wire wb_stb_o, wb_cyc_o, wb_we_o;
    wire [6:0] wb_adr_o;
    wire [31:0] wb_dat_o;
    wire [31:0] wb_dat_i;
    wire wb_ack_i;
    spiwb command_builder(
        .clk(clk), .rst(!rst_n),

        .pin_cs(spi_cs), .pin_mosi(spi_mosi), .pin_miso(spi_miso),
        .pin_sclk(spi_sclk),

        .wb_stb_o(wb_stb_o), .wb_cyc_o(wb_cyc_o), .wb_we_o(wb_we_o),
        .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o),
        .wb_dat_i(wb_dat_i), .wb_ack_i(wb_ack_i)
        );

    // Output pin configuration
    wire pcfg_step_pulse, pcfg_step_dir;
    wire pcfg_wb_stb_i, pcfg_wb_cyc_i, pcfg_wb_we_i;
    wire [3:0] pcfg_wb_adr_i;
    wire [31:0] pcfg_wb_dat_i;
    wire [31:0] pcfg_wb_dat_o;
    wire pcfg_wb_ack_o;
    pincfg pin_configuration(
        .clk(clk), .rst(!rst_n),

        .pins_out(uo_out), .pin_shutdown(signal_shutdown),
        .step_pulse(pcfg_step_pulse), .step_dir(pcfg_step_dir),

        .wb_stb_i(pcfg_wb_stb_i), .wb_cyc_i(pcfg_wb_cyc_i),
        .wb_we_i(pcfg_wb_we_i),
        .wb_adr_i(pcfg_wb_adr_i), .wb_dat_i(pcfg_wb_dat_i),
        .wb_dat_o(pcfg_wb_dat_o), .wb_ack_o(pcfg_wb_ack_o)
        );

    // Movement queue
    wire [64:0] mq_data;
    wire mq_avail, mq_pull;
    wire mq_wb_stb_i, mq_wb_cyc_i, mq_wb_we_i;
    wire [3:0] mq_wb_adr_i;
    wire [31:0] mq_wb_dat_i;
    wire [31:0] mq_wb_dat_o;
    wire mq_wb_ack_o;
    moveq movement_queue(
        .clk(clk), .rst(!rst_n),

        .pin_have_space(signal_irq),
        .mq_data(mq_data), .mq_avail(mq_avail), .mq_pull(mq_pull),

        .wb_stb_i(mq_wb_stb_i), .wb_cyc_i(mq_wb_cyc_i),
        .wb_we_i(mq_wb_we_i),
        .wb_adr_i(mq_wb_adr_i), .wb_dat_i(mq_wb_dat_i),
        .wb_dat_o(mq_wb_dat_o), .wb_ack_o(mq_wb_ack_o)
        );

    // Scheduler for step signal
    wire [31:0] counter;
    wire sstep_wb_stb_i, sstep_wb_cyc_i, sstep_wb_we_i;
    wire [3:0] sstep_wb_adr_i;
    wire [31:0] sstep_wb_dat_i;
    wire [31:0] sstep_wb_dat_o;
    wire sstep_wb_ack_o;
    schedstep schedule_step(
        .clk(clk), .rst(!rst_n),

        .step_pulse(pcfg_step_pulse), .step_dir(pcfg_step_dir),
        .counter(counter),
        .mq_data(mq_data), .mq_avail(mq_avail), .mq_pull(mq_pull),

        .wb_stb_i(sstep_wb_stb_i), .wb_cyc_i(sstep_wb_cyc_i),
        .wb_we_i(sstep_wb_we_i),
        .wb_adr_i(sstep_wb_adr_i), .wb_dat_i(sstep_wb_dat_i),
        .wb_dat_o(sstep_wb_dat_o), .wb_ack_o(sstep_wb_ack_o)
        );

    // Clock counter
    wire cntr_wb_stb_i, cntr_wb_cyc_i, cntr_wb_we_i;
    wire [3:0] cntr_wb_adr_i;
    wire [31:0] cntr_wb_dat_i;
    wire [31:0] cntr_wb_dat_o;
    wire cntr_wb_ack_o;
    clockcounter clock_counter(
        .clk(clk), .rst(!rst_n),

        .counter(counter),

        .wb_stb_i(cntr_wb_stb_i), .wb_cyc_i(cntr_wb_cyc_i),
        .wb_we_i(cntr_wb_we_i),
        .wb_adr_i(cntr_wb_adr_i), .wb_dat_i(cntr_wb_dat_i),
        .wb_dat_o(cntr_wb_dat_o), .wb_ack_o(cntr_wb_ack_o)
        );

    // Bus routing
    busdispatch bus_dispatcher(
        .clk(clk), .rst(!rst_n),

        .wb_stb_i(wb_stb_o), .wb_cyc_i(wb_cyc_o), .wb_we_i(wb_we_o),
        .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o), .wb_dat_o(wb_dat_i),
        .wb_ack_o(wb_ack_i),

        .pcfg_wb_stb_o(pcfg_wb_stb_i), .pcfg_wb_cyc_o(pcfg_wb_cyc_i),
        .pcfg_wb_we_o(pcfg_wb_we_i),
        .pcfg_wb_adr_o(pcfg_wb_adr_i), .pcfg_wb_dat_o(pcfg_wb_dat_i),
        .pcfg_wb_dat_i(pcfg_wb_dat_o), .pcfg_wb_ack_i(pcfg_wb_ack_o),

        .mq_wb_stb_o(mq_wb_stb_i), .mq_wb_cyc_o(mq_wb_cyc_i),
        .mq_wb_we_o(mq_wb_we_i),
        .mq_wb_adr_o(mq_wb_adr_i), .mq_wb_dat_o(mq_wb_dat_i),
        .mq_wb_dat_i(mq_wb_dat_o), .mq_wb_ack_i(mq_wb_ack_o),

        .sstep_wb_stb_o(sstep_wb_stb_i), .sstep_wb_cyc_o(sstep_wb_cyc_i),
        .sstep_wb_we_o(sstep_wb_we_i),
        .sstep_wb_adr_o(sstep_wb_adr_i), .sstep_wb_dat_o(sstep_wb_dat_i),
        .sstep_wb_dat_i(sstep_wb_dat_o), .sstep_wb_ack_i(sstep_wb_ack_o),

        .cntr_wb_stb_o(cntr_wb_stb_i), .cntr_wb_cyc_o(cntr_wb_cyc_i),
        .cntr_wb_we_o(cntr_wb_we_i),
        .cntr_wb_adr_o(cntr_wb_adr_i), .cntr_wb_dat_o(cntr_wb_dat_i),
        .cntr_wb_dat_i(cntr_wb_dat_o), .cntr_wb_ack_i(cntr_wb_ack_o)
        );

endmodule
