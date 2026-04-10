`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// gen_fast.v
// sine-wave generator to replace fast sqr_ signals. This is a DDS.
// created 20/7/2025 by Andi
// output of a phase-shifted sine-wave loaded from file.
// file contains full-wave or half-wave sine formated as binary string, one entry per line.
// use several generators to get modulation and demodulation signals. use sync input to synchronize phase.
// WIDTH        = number of bits of output signal
// ADDR_WIDTH   = number of entries in FILE = 2^ADDR_WIDTH 
// FTW_WIDTH    = number of bits in ftw. defines frequency resolution = FS/2^(FTW_WIDTH+1) with FS = clock frequency.
// FILE         = path and file name for waveform. can be relative to project location.
// HALF_WAVE    = if nonzero file contains half-wave and second half is inverted signal.
// clk          = clock input, typically 125MHz = 8ns
// sync         = set for one cycle when ftw or pts were changed. set simultaneously on several channels to synchronize phase.
// ptw          = phase tuning word.     phase     = ptw*360°/2^(ADDR_WIDTH+1)
// ftw          = frequency tuning word. frequency = ftw*FS  /2^(FTW_WIDTH +1)
// last change 27/7/2025 by Andi
//////////////////////////////////////////////////////////////////////////////////

module gen_fast # (
    parameter integer WIDTH         = 14,                    // number of data bits
    parameter integer ADDR_WIDTH    = 13,                    // number of address bits
    parameter integer FTW_WIDTH     = 27,                    // width of frequency tuning word
    parameter         FILE          = "./rtl/lock/sin_half.bin", // filename
    parameter integer HALF_WAVE     = 1                      // file is half-wave (nonzero) or full-wave (0)
)
(
    input                          clk,                     // clock
    input                          sync,                    // sync input
    input         [ADDR_WIDTH  :0] ptw,                     // phase tuning word
    input         [FTW_WIDTH -1:0] ftw,                     // frequency tuning word
    output signed [WIDTH     -1:0] signal,                  // output signal
    output                         trigger                  // trigger at 0 phase of signal
);

    localparam integer DEPTH   = 1<<ADDR_WIDTH;             // number of elements in RAM
    localparam integer RAM_LAT = 2;                         // latency of RAM: with output buffer 2 cycles, otherwise 1 cycle

    reg         [FTW_WIDTH   :0] acc;                       // phase accumulator +1 bit to detect sign change
    wire        [ADDR_WIDTH-1:0] addr;                      // address in RAM
    wire signed [WIDTH     -1:0] raw ;                      // raw data from RAM
    reg signed  [WIDTH     -1:0] sig_ff;                    // output signal register
    reg                          trg_ff;                    // output trigger register
    wire                         inv = acc[FTW_WIDTH];      // sign change when RAM 1x read
    reg         [RAM_LAT   -1:0] inv_ff;                    // delayed sign change
    
    if (HALF_WAVE == 0) // map highest ADDR_WIDTH acc bits to address
        assign addr = acc[FTW_WIDTH   -: ADDR_WIDTH];
    else // map 2nd to highest ADDR_WIDTH acc bits to address
        assign addr = acc[FTW_WIDTH-1 -: ADDR_WIDTH];

    // load half sine-wave from file into (B)RAM
    red_pitaya_RAM # (
        .WIDTH      (WIDTH),
        .DEPTH      (DEPTH),                                // number of elements in RAM
        .ADDR_WIDTH (ADDR_WIDTH),
        .INIT_FILE  (FILE),
        .OUT_BUF    (1)                                     // output buffer recommended for better performance
    )
    sin_half (
        .clk        (clk),
        .we         (1'b0),                                 // write option is not used
        .addr       (addr),                                 // read address
        .din        ({WIDTH{1'b0}}),                        // write option is not used
        .dout       (raw)                                   // raw data out. RAM_LAT cycles latency
    );
    
    // generate output signal
    always @ (posedge clk) begin
        acc         <= (sync) ? {ptw, {(FTW_WIDTH-ADDR_WIDTH){1'b0}}} : acc + {1'b0,ftw};
        inv_ff      <= {inv_ff[RAM_LAT-1:0], inv};
        if (HALF_WAVE == 0) begin
            sig_ff  <= $signed(raw);
        end
        else begin
            sig_ff  <= inv_ff[RAM_LAT-1] ? $signed(-raw) : $signed(raw);
        end
        if (RAM_LAT > 1)
            trg_ff  <= (sync) ? 1'b0 : inv_ff[RAM_LAT-1 -: 2] == 2'b10;
        else
            trg_ff  <= (sync) ? 1'b0 : {inv_ff[0], inv} == 2'b10;
    end

    // assign output signals
    assign signal  = sig_ff;
    assign trigger = trg_ff;

endmodule

