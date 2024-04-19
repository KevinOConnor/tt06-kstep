/* Store upcoming movements in a queue
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

module moveq (
    input clk, rst,

    output pin_have_space,
    output [64:0] mq_data, output mq_avail, input mq_pull,

    input wb_stb_i, input wb_cyc_i, input wb_we_i,
    input [3:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    output wb_ack_o
    );

    // Just a single item in the queue for now
    reg [64:0] queue;

    // Support filling queue entry from wb
    wire is_command_set_interval, is_command_set_countadd;
    wire next_dir;
    reg in_use;
    wire have_space = !in_use || mq_pull;
    always @(posedge clk) begin
        if (rst)
            in_use <= 0;
        else if (have_space && is_command_set_countadd)
            in_use <= 1;
        else if (in_use && mq_pull)
            in_use <= 0;
    end
    always @(posedge clk) begin
        if (rst)
            queue <= 0;
        else if (have_space && is_command_set_interval)
            queue[63:32] <= wb_dat_i;
        else if (have_space && is_command_set_countadd) begin
            queue[64] <= next_dir;
            queue[31:0] <= wb_dat_i;
        end
    end
    assign mq_data = queue;
    assign mq_avail = in_use;
    assign pin_have_space = !in_use;

    // Stepper direction tracking
    wire is_command_set_dir;
    reg upcoming_dir;
    always @(posedge clk) begin
        if (rst)
            upcoming_dir <= 0;
        else if (is_command_set_dir)
            upcoming_dir <= wb_dat_i[0];
    end
    assign next_dir = upcoming_dir;

    // Wishbone command handling
    wire is_command = wb_cyc_i && wb_stb_i && wb_we_i;
    assign is_command_set_countadd = is_command && wb_adr_i == 0;
    assign is_command_set_interval = is_command && wb_adr_i == 1;
    assign is_command_set_dir = is_command && wb_adr_i == 2;
    assign wb_dat_o = 0;
    assign wb_ack_o = 1;

endmodule
