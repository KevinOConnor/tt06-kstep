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
    output reg cntr_wb_stb_o, output cntr_wb_cyc_o, output cntr_wb_we_o,
    output [3:0] cntr_wb_adr_o, output [31:0] cntr_wb_dat_o,
    input [31:0] cntr_wb_dat_i, input cntr_wb_ack_i
    );

    // Module assignment
    localparam CNTR_ADDR = 3'h7;
    assign cntr_wb_cyc_o=wb_cyc_i, cntr_wb_we_o=wb_we_i;
    assign cntr_wb_adr_o=wb_adr_i, cntr_wb_dat_o=wb_dat_i;

    always @(*) begin
        cntr_wb_stb_o = 0;

        case (wb_adr_i[6:4])
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
