/* SPI to wishbone interface
 *
 * Copyright (c) 2024  Kevin O'Connor <kevin@koconnor.net>
 * SPDX-License-Identifier: Apache-2.0
 */

module spiwb (
    input clk, rst,

    input pin_cs, input pin_mosi, output pin_miso, input pin_sclk,

    output reg wb_stb_o, output wb_cyc_o, output wb_we_o,
    output [6:0] wb_adr_o,
    output [31:0] wb_dat_o,
    input [31:0] wb_dat_i,
    input wb_ack_i
    );

    // Buffers for inputs (avoid metastability)
    reg [1:0] buf_cs;
    always @(posedge clk)
        buf_cs <= { buf_cs[0], pin_cs };
    reg [1:0] buf_mosi;
    always @(posedge clk)
        buf_mosi <= { buf_mosi[0], pin_mosi };
    reg [2:0] buf_sclk;
    always @(posedge clk)
        buf_sclk <= { buf_sclk[1:0], pin_sclk };
    wire cs = buf_cs[1], mosi = buf_mosi[1], sclk = buf_sclk[1];

    // Detect rising edge of sclk
    wire is_sclk_rise = !cs && !buf_sclk[2] && buf_sclk[1];

    // State tracking for input message reading
    wire is_cmd_busy;
    localparam GET_RW=0, GET_ADDR=1, GET_DATA=8, DONE=40;
    reg [5:0] recv_state;
    always @(posedge clk) begin
        if (rst) begin
            recv_state <= GET_RW;
        end else if (cs) begin
            if (is_cmd_busy)
                recv_state <= DONE;
            else
                recv_state <= GET_RW;
        end else if (is_sclk_rise) begin
            if (recv_state != DONE)
                recv_state <= recv_state + 1;
        end
    end

    // Is a read or write spi request
    reg is_write;
    always @(posedge clk)
        if (is_sclk_rise && recv_state == GET_RW)
            is_write <= mosi;

    // Address of request
    reg [6:0] addr;
    always @(posedge clk)
        if (is_sclk_rise && recv_state >= GET_ADDR && recv_state < GET_DATA)
            addr <= { addr[5:0], mosi };

    // Data for a read/write requests
    wire is_read_data_avail;
    reg [31:0] req_data;
    always @(posedge clk) begin
        if (rst)
            req_data <= 0;
        else if (is_sclk_rise && recv_state >= GET_DATA && recv_state < DONE)
            req_data <= { req_data[30:0], mosi };
        else if (is_read_data_avail)
            req_data <= wb_dat_i;
    end
    reg miso;
    always @(posedge clk) begin
        if (rst)
            miso <= 0;
        else if (!cs && !sclk)
            miso <= req_data[31];
    end
    assign pin_miso = miso;

    // Indicate a wishbone request should be made
    wire is_spi_request = is_sclk_rise && ((is_write && recv_state == DONE - 1)
         || (!is_write && recv_state == GET_DATA - 1));

    // Create wishbone command request
    assign is_cmd_busy = wb_stb_o && !wb_ack_i;
    always @(posedge clk) begin
        if (rst)
            wb_stb_o <= 0;
        else if (!is_cmd_busy)
            wb_stb_o <= is_spi_request;
    end
    assign is_read_data_avail = !is_write && wb_stb_o && wb_ack_i;

    // Assign wishbone bus signals
    assign wb_cyc_o = wb_stb_o;
    assign wb_we_o = is_write;
    assign wb_adr_o = addr;
    assign wb_dat_o = req_data;

endmodule
