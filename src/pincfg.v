/* Configure output pins
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

module pincfg (
    input clk, rst,

    input step_pulse,
    output [7:0] pins_out, input pin_shutdown,

    input wb_stb_i, input wb_cyc_i, input wb_we_i,
    input [3:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    output wb_ack_o
    );

    // Main pin polarity
    wire is_command_set_polarity;
    reg [7:0] polarity;
    always @(posedge clk) begin
        if (rst)
            polarity <= 0;
        else if (is_command_set_polarity)
            polarity <= wb_dat_i;
    end

    // Step pin pulsing
    reg in_step_pulse;
    always @(posedge clk)
        in_step_pulse <= step_pulse;

    // Shutdown tracking
    reg [1:0] buf_shutdown;
    always @(posedge clk)
        buf_shutdown <= { buf_shutdown[0], pin_shutdown };
    reg in_shutdown;
    wire is_command_clear_shutdown;
    always @(posedge clk) begin
        if (rst || is_command_clear_shutdown)
            in_shutdown <= 0;
        else if (buf_shutdown[1])
            in_shutdown <= 1;
    end
    wire is_pulse_active = in_step_pulse && !in_shutdown;

    // Pin output
    assign pins_out[0] = polarity[0] ^ is_pulse_active;
    assign pins_out[7:1] = polarity[7:1];

    // Wishbone command handling
    wire is_command = wb_cyc_i && wb_stb_i && wb_we_i;
    assign is_command_set_polarity = is_command && wb_adr_i == 0;
    assign is_command_clear_shutdown = is_command && wb_adr_i == 1;
    assign wb_dat_o = 0;
    assign wb_ack_o = 1;

endmodule
