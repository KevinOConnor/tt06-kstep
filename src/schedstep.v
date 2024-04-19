/* Scheduling of step signals
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

module schedstep (
    input clk, rst,

    output step_pulse, output reg step_dir,
    input [31:0] counter,
    input [64:0] mq_data, input mq_avail, output mq_pull,

    input wb_stb_i, input wb_cyc_i, input wb_we_i,
    input [3:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    output wb_ack_o
    );

    // Current schedule
    reg [31:0] interval;
    reg [15:0] count;
    reg [15:0] add;
    wire [31:0] sadd = { add[15] ? 16'hffff : 16'h0000, add };
    wire next_step_dir = mq_data[64];
    wire [31:0] next_interval = mq_data[63:32];
    wire [15:0] next_count = mq_data[31:16];
    wire [15:0] next_add = mq_data[15:0];
    wire [31:0] next_sadd = { next_add[15] ? 16'hffff : 16'h0000, next_add };
    wire is_active = count != 0;
    reg [31:0] next_step_clock;
    wire is_command_reset;
    always @(posedge clk) begin
        if (rst) begin
            next_step_clock <= 0;
            count <= 0;
            step_dir <= 0;
        end else if (!is_active && is_command_reset) begin
            next_step_clock <= 0;
        end else if (step_pulse) begin
            next_step_clock <= next_step_clock + interval;
            interval <= interval + sadd;
            count <= count - 1;
        end else if (mq_pull) begin
            next_step_clock <= next_step_clock + next_interval;
            interval <= next_interval + next_sadd;
            count <= next_count;
            add <= next_add;
            step_dir <= next_step_dir;
        end
    end
    assign step_pulse = is_active && next_step_clock == counter;
    assign mq_pull = mq_avail && !is_active;

    // Wishbone command handling
    wire is_command = wb_cyc_i && wb_stb_i && wb_we_i;
    assign is_command_reset = is_command && wb_adr_i == 0;
    assign wb_dat_o = 0;
    assign wb_ack_o = 1;

endmodule
