/* Route wishbone bus messages to modules
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

module busdispatch (
    input clk, input rst,

    // Requester wishbone module
    input wb_stb_i, input wb_cyc_i, input wb_we_i,
    input [6:0] wb_adr_i, input [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o, output reg wb_ack_o,

    // Modules
    output reg pcfg_wb_stb_o, output pcfg_wb_cyc_o, output pcfg_wb_we_o,
    output [3:0] pcfg_wb_adr_o, output [31:0] pcfg_wb_dat_o,
    input [31:0] pcfg_wb_dat_i, input pcfg_wb_ack_i,

    output reg mq_wb_stb_o, output mq_wb_cyc_o, output mq_wb_we_o,
    output [3:0] mq_wb_adr_o, output [31:0] mq_wb_dat_o,
    input [31:0] mq_wb_dat_i, input mq_wb_ack_i,

    output reg sstep_wb_stb_o, output sstep_wb_cyc_o, output sstep_wb_we_o,
    output [3:0] sstep_wb_adr_o, output [31:0] sstep_wb_dat_o,
    input [31:0] sstep_wb_dat_i, input sstep_wb_ack_i,

    output reg cntr_wb_stb_o, output cntr_wb_cyc_o, output cntr_wb_we_o,
    output [3:0] cntr_wb_adr_o, output [31:0] cntr_wb_dat_o,
    input [31:0] cntr_wb_dat_i, input cntr_wb_ack_i
    );

    // Module assignment
    localparam PCFG_ADDR = 3'h1;
    assign pcfg_wb_cyc_o=wb_cyc_i, pcfg_wb_we_o=wb_we_i;
    assign pcfg_wb_adr_o=wb_adr_i[3:0], pcfg_wb_dat_o=wb_dat_i;
    localparam MQ_ADDR = 3'h2;
    assign mq_wb_cyc_o=wb_cyc_i, mq_wb_we_o=wb_we_i;
    assign mq_wb_adr_o=wb_adr_i[3:0], mq_wb_dat_o=wb_dat_i;
    localparam SSTEP_ADDR = 3'h3;
    assign sstep_wb_cyc_o=wb_cyc_i, sstep_wb_we_o=wb_we_i;
    assign sstep_wb_adr_o=wb_adr_i[3:0], sstep_wb_dat_o=wb_dat_i;
    localparam CNTR_ADDR = 3'h7;
    assign cntr_wb_cyc_o=wb_cyc_i, cntr_wb_we_o=wb_we_i;
    assign cntr_wb_adr_o=wb_adr_i[3:0], cntr_wb_dat_o=wb_dat_i;

    always @(*) begin
        pcfg_wb_stb_o = 0;
        mq_wb_stb_o = 0;
        sstep_wb_stb_o = 0;
        cntr_wb_stb_o = 0;

        case (wb_adr_i[6:4])
        PCFG_ADDR: begin
            pcfg_wb_stb_o = wb_stb_i;
            wb_dat_o = pcfg_wb_dat_i;
            wb_ack_o = pcfg_wb_ack_i;
        end
        MQ_ADDR: begin
            mq_wb_stb_o = wb_stb_i;
            wb_dat_o = mq_wb_dat_i;
            wb_ack_o = mq_wb_ack_i;
        end
        SSTEP_ADDR: begin
            sstep_wb_stb_o = wb_stb_i;
            wb_dat_o = sstep_wb_dat_i;
            wb_ack_o = sstep_wb_ack_i;
        end
        CNTR_ADDR: begin
            cntr_wb_stb_o = wb_stb_i;
            wb_dat_o = cntr_wb_dat_i;
            wb_ack_o = cntr_wb_ack_i;
        end
        default: begin
            wb_dat_o = 0;
            wb_ack_o = 1;
        end
        endcase
    end

endmodule
