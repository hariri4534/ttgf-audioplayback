`default_nettype none

module playback_ctrl #(parameter LINE_SIZE=16) (
    input  wire        clk,
    input  wire        rst_n,

    // Interface to QSPI Controller
    input  wire [(LINE_SIZE*8)-1:0]  data_i,    // Data from Flash (assuming LINE_SIZE=1)
    input  wire        rd_en_i,   // 'done' signal from QSPI
    output reg  [23:0] addr_o,    // Current read address
    output reg         rd_o,      // Trigger a new read

    // Interface to PWM
    output reg  [7:0]  sample_o   // 8-bit PCM sample to PWM
);

localparam ADDR_PAD = 24 - $clog2(LINE_SIZE);
logic [LINE_SIZE*8-1:0] data_buf_q;
logic [$clog2(LINE_SIZE)-1:0] addr_offset;

logic [23:0] addr_q, addr_nxt;
logic [7:0] count_q, count_nxt;
logic [$clog2(LINE_SIZE)-1:0] sample_ptr_q;
logic [$clog2(LINE_SIZE)-1:0] sample_ptr_nxt;
logic [7:0] pwm_data;
logic next_sample;
logic rd_q;

always_ff @( posedge clk ) if (rd_en_i) data_buf_q <= data_i;


// audio playback management
// count up to 255 cycles
always_ff @(posedge clk) begin
    if (~rst_n) begin
        count_q <= '0;
        sample_ptr_q <= '0;
    end else begin
        count_q <= count_nxt;
        sample_ptr_q <= sample_ptr_nxt;
    end
end

assign next_sample      = (count_q == 8'hfe);
assign count_nxt        = next_sample ? '0 : count_q + 1'b1;
// TODO: Adjust playback by adjusting increment
assign sample_ptr_nxt   = next_sample ? sample_ptr_q + 1'b1
                                      : sample_ptr_q;


// Binary coded mux to select sample data for PWM
genvar i;
logic [7:0] pwm_data_gen [LINE_SIZE-1:0];
generate
    for (i=0; i < LINE_SIZE; i++) begin
        assign pwm_data_gen [i] = {8{(sample_ptr_q == i)}} & data_buf_q[i*8 +: 8];
    end
endgenerate

always_comb begin
    for (int i=0; i < LINE_SIZE; i++) begin
        pwm_data = pwm_data | pwm_data_gen[i];
    end
end

always_ff @(posedge clk) begin
    if (~rst_n) begin
        rd_q        <= '0;
        addr_q      <= '0;
    end
        rd_q        <= rd_en_i;
        addr_q      <= addr_nxt;
end

assign addr_offset[$clog2(LINE_SIZE)-1]     = 1'b1;
assign addr_offset[$clog2(LINE_SIZE)-2:0]   = '0;
assign addr_nxt = rd_en_i ? addr_q + { {ADDR_PAD{1'b0}}, addr_offset }
                          : addr_q;

// TODO: Change the rd_o signal, need few consideration on how to assert read request

assign rd_o     = rd_q;
assign addr_o   = addr_q;
assign sample_o = pwm_data;



endmodule
