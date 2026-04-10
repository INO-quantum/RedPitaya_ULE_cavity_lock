// Initializing Block RAM from external data file
// Binary data
// File: rams_init_file.v
// see p.151: https://docs.amd.com/v/u/2018.3-English/ug901-vivado-synthesis

`timescale 1ns / 1ps

module red_pitaya_RAM # (
    parameter WIDTH      = 32,
    parameter DEPTH      = 64,
    parameter ADDR_WIDTH = 6,
    parameter INIT_FILE  = "",
    parameter OUT_BUF    = 0
)
(
    input  wire clk,
    input  wire we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    reg  [WIDTH-1:0] ram [0:DEPTH-1];
    reg  [WIDTH-1:0] dout_ff;

    generate
    if (INIT_FILE != "") begin
        initial begin
            $readmemb(INIT_FILE, ram);
        end
    end
    endgenerate

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
        dout_ff <= ram[addr];
    end 


    if (OUT_BUF != 0) begin
        reg [WIDTH-1:0] out_buf;
        always @(posedge clk) begin
            out_buf <= dout_ff;
        end 
        assign dout = out_buf;
    end
    else begin
        assign dout = dout_ff;
    end

endmodule


