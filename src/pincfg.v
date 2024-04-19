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

    // Pin output
    assign pins_out = polarity;

    // Wishbone command handling
    wire is_command = wb_cyc_i && wb_stb_i && wb_we_i;
    assign is_command_set_polarity = is_command && wb_adr_i == 0;
    assign wb_dat_o = 0;
    assign wb_ack_o = 1;

endmodule
