module datapath(
    input wire [63 : 0] istream_msg, //input stream message
    input wire [4 : 0] sparse_count,
    input clk,
    input rst,
    input state_done,
    input b_mux_sel,
    input a_mux_sel,
    input r_mux_sel,
    input add_mux_sel,
    input r_en,
    output b_lsb, //lsb : left significant bit
    output wire [31 : 0] ostream_msg,
    output reg [31 : 0] b_reg
); 

    wire [31 : 0] b_mux_out, b_rs_out; //rs : right shift
    wire [31 : 0] a_mux_out, a_ls_out; //ls : left shift
    wire [31 : 0] r_mux1_out, r_mux2_out, partial_sum;
    wire [31 : 0] a = istream_msg[63 : 32];
    wire [31 : 0] b = istream_msg[31 : 0];
    reg  [31 : 0] a_reg, r_reg;
    

    assign b_mux_out  = (b_mux_sel) ? b_rs_out : b;
    assign a_mux_out  = (a_mux_sel) ? a_ls_out : a;
    assign r_mux1_out = (r_mux_sel) ? r_mux2_out : 32'b0;
    assign r_mux2_out  = (add_mux_sel) ? partial_sum : r_reg;

    always @(posedge clk) begin
        if(rst) begin
            b_reg <= 32'd0;
            a_reg <= 32'd0;
            r_reg <= 32'd0;  
        end
        else begin
            b_reg <= b_mux_out;
            a_reg <= a_mux_out;
            if (r_en) r_reg <= r_mux1_out;
        end
    end

    assign b_rs_out = (!state_done) ? (b_reg >> sparse_count) : b_reg;
    assign a_ls_out = (!state_done) ? (a_reg << sparse_count) : a_reg;

    assign b_lsb = b_reg[0];
    assign ostream_msg = r_reg;
    assign partial_sum = a_reg + r_reg;

endmodule