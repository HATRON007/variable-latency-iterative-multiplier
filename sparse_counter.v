module sparse_counter(
    input rst,
    input wire [31 : 0] b_reg,
    output reg [4 : 0] sparse_count
);
    integer i;
    reg stop;

    always @(*) begin
        if(rst) begin
            sparse_count = 5'd0;
            stop = 1;
        end
        else begin
            stop = 1;
            sparse_count = 5'd0;
            for(i = 0; i < 32; i = i + 1) begin
                if(stop) begin
                    if(b_reg[i] == 1'b1) begin
                        sparse_count = i;
                        stop = 0;
                    end
                end
            end
            if(sparse_count == 5'd0) sparse_count = 5'd1;
        end
    end

endmodule