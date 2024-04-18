/* Simple clock counter accessible via wishbone bus
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

module clockcounter (
    input clk, rst,

    output reg [31:0] counter,

    input wb_stb_i, input wb_cyc_i, input wb_we_i,
    input [3:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    output wb_ack_o
    );

    // Main counter
    wire is_command_set_counter;
    always @(posedge clk) begin
        if (rst)
            counter <= 0;
        else if (is_command_set_counter)
            counter <= wb_dat_i;
        else
            counter <= counter + 1;
    end

    // Wishbone command handling
    wire is_command = wb_cyc_i && wb_stb_i && wb_we_i;
    assign is_command_set_counter = is_command && wb_adr_i == 0;
    assign wb_dat_o = counter;
    assign wb_ack_o = 1;

endmodule
