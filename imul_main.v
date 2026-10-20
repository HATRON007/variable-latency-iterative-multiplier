module imul_main(
    input clk,
    input rst,

    input wire signed [63 : 0] istream_msg,
    input wire istream_val,
    output wire istream_rdy,

    output wire [31 : 0] ostream_msg,
    output wire ostream_val,
    input wire  ostream_rdy
);

    wire b_lsb, state_done, r_en, load_pulse;
    wire [4 : 0] sparse_count;
    wire a_mux_sel, b_mux_sel, r_mux_sel, add_mux_sel;
    wire signed [31 : 0] b_reg;
    
    reg sign_f;
    always @(posedge clk) begin
        if (rst) sign_f <= 1'b0;
        else if (load_pulse) sign_f <= istream_msg[63] ^ istream_msg[31];
    end

    wire sign_a = istream_msg[63];
    wire sign_b = istream_msg[31];
    wire [31 : 0] istream_a = (!sign_a) ? istream_msg[63 : 32] : ((~istream_msg[63 : 32]) + 32'd1);
    wire [31 : 0] istream_b = (!sign_b) ? istream_msg[31 : 0]  : ((~istream_msg[31 : 0])  + 32'd1);
    wire [63 : 0] istream_msg_mod = {istream_a, istream_b}; 

    wire [31 : 0] ostream_msg_mod;
    assign ostream_msg = (!sign_f) ? ostream_msg_mod : ((~ostream_msg_mod) + 32'd1);
    

    control_unit ctrl (
        .clk(clk),
        .rst(rst),
        .b_lsb(b_lsb),
        .istream_rdy(istream_rdy),
        .istream_val(istream_val),
        .ostream_rdy(ostream_rdy),
        .ostream_val(ostream_val),
        .a_mux_sel(a_mux_sel),
        .b_mux_sel(b_mux_sel),
        .r_mux_sel(r_mux_sel),
        .add_mux_sel(add_mux_sel),
        .r_en(r_en),
        .load_pulse(load_pulse),
        .state_done(state_done),
        .sparse_count(sparse_count),
        .b_reg(b_reg)
    );

    datapath data (
        .clk(clk),
        .rst(rst),
        .istream_msg(istream_msg_mod),
        .ostream_msg(ostream_msg_mod),
        .state_done(state_done),
        .a_mux_sel(a_mux_sel),
        .b_mux_sel(b_mux_sel),
        .r_mux_sel(r_mux_sel),
        .add_mux_sel(add_mux_sel),
        .r_en(r_en),
        .b_lsb(b_lsb),
        .sparse_count(sparse_count),
        .b_reg(b_reg)
    );

endmodule