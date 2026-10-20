`timescale 1ns/1ps

module testbench;

    reg clk = 0;
    reg rst;
    reg  [63:0] istream_msg;
    reg istream_val;
    wire istream_rdy;
    wire [31:0] ostream_msg;
    wire ostream_val;
    reg ostream_rdy;

    imul_main dut (
        .clk(clk), .rst(rst),
        .istream_msg(istream_msg), .istream_val(istream_val), .istream_rdy(istream_rdy),
        .ostream_msg(ostream_msg), .ostream_val(ostream_val), .ostream_rdy(ostream_rdy)
    );

    always #5 clk = ~clk;

    localparam N = 14;
    reg [31:0] a_t [0:N-1];
    reg [31:0] b_t [0:N-1];
    reg [31:0] exp;
    integer i, wait_cnt, errors;

    initial begin
        // zero cases
        a_t[0]  = 0;            b_t[0]  = 0;
        a_t[1]  = 5;            b_t[1]  = 0;
        a_t[2]  = 0;            b_t[2]  = 5;
        // plain and signed
        a_t[3]  = 1;            b_t[3]  = 1;
        a_t[4]  = 7;            b_t[4]  = 9;
        a_t[5]  = -7;           b_t[5]  = 9;
        a_t[6]  = 7;            b_t[6]  = -9;
        a_t[7]  = -7;           b_t[7]  = -9;
        // sparse b, bits far apart
        a_t[8]  = 12345;        b_t[8]  = 32'h00010000;
        a_t[9]  = 99;           b_t[9]  = 32'h80000001;
        // dense b
        a_t[10] = 99;           b_t[10] = 32'hFFFFFFFF;
        // limits and overflow
        a_t[11] = 32'h7FFFFFFF; b_t[11] = 2;
        a_t[12] = 32'h80000000; b_t[12] = 1;
        a_t[13] = 32'h80000000; b_t[13] = 32'hFFFFFFFF;
    end

    initial begin
        errors = 0;
        rst = 1; istream_val = 0; ostream_rdy = 0; istream_msg = 0;
        repeat (3) @(posedge clk);
        #1 rst = 0;

        for (i = 0; i < N; i = i + 1) begin
            exp = $signed(a_t[i]) * $signed(b_t[i]);

            @(negedge clk);
            istream_msg = {a_t[i], b_t[i]};
            istream_val = 1;
            @(posedge clk);
            #1 istream_val = 0;

            wait_cnt = 0;
            while (!ostream_val && wait_cnt < 100) begin
                @(negedge clk);
                wait_cnt = wait_cnt + 1;
            end

            // stall the consumer a few cycles to check output holds
            repeat (i % 3) @(negedge clk);

            if (ostream_msg !== exp) begin
                errors = errors + 1;
                $display("FAIL case %0d : %0d * %0d = %0d, expected %0d",
                         i, $signed(a_t[i]), $signed(b_t[i]),
                         $signed(ostream_msg), $signed(exp));
            end
            else
                $display("pass case %0d : %0d * %0d = %0d (%0d cycles)",
                         i, $signed(a_t[i]), $signed(b_t[i]),
                         $signed(ostream_msg), wait_cnt);

            ostream_rdy = 1;
            @(posedge clk);
            #1 ostream_rdy = 0;
        end

        if (errors === 0) $display("ALL PASSED");
        else              $display("%0d FAILED", errors);
        $finish;
    end

endmodule