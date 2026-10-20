module control_unit #(parameter sparse_on = 1)(
    input clk,
    input rst,
    input b_lsb,
    input istream_val,
    input ostream_rdy,
    input wire [31 : 0] b_reg,
    output reg istream_rdy,
    output reg ostream_val,
    output reg b_mux_sel,
    output reg a_mux_sel,
    output reg r_mux_sel,
    output reg add_mux_sel,
    output reg r_en,
    output reg load_pulse,
    output reg state_done,
    output wire [4 : 0] sparse_count
);

    //s1,s2,s3 - FSM states
    //s1:idle, s2:calc, s3:done

    wire [4 : 0] count;

    sparse_counter sc(
        .rst(rst),
        .b_reg(b_reg),
        .sparse_count(count)
    );

    assign sparse_count = (sparse_on)? count : 5'd1;

    parameter s1 = 2'd1, s2 = 2'd2, s3 = 2'd3;
    reg [1 : 0] state;
    reg [1 : 0] next_state;
    reg [5 : 0] counter;

    always @(posedge clk) begin
        if(rst) begin
            state <= s1;
            counter <= 6'b0;
        end

        else begin
            state <= next_state;
            if(state == s1) counter <= 6'b0;
            if(state == s2) counter <= counter + sparse_count;
        end
    end

    always @(*) begin
        b_mux_sel = 1'b1;
        a_mux_sel = 1'b1;
        r_mux_sel = 1'b0;
        state_done = 1'b0;
        next_state = state;
        add_mux_sel = 1'b0;
        r_en = 1'b0;
        istream_rdy = 1'b0;
        ostream_val = 1'b0;
        load_pulse = 1'b0;

        case(state)

        s1: begin //idle state
                istream_rdy = 1'b1;
                if(istream_val) begin
                    b_mux_sel  = 1'b0;
                    a_mux_sel  = 1'b0;
                    r_mux_sel  = 1'b0;
                    r_en       = 1'b1;
                    load_pulse = 1'b1;
                    next_state = s2;
                end
            end

        s2: begin //computation state
                b_mux_sel = 1'b1;
                a_mux_sel = 1'b1;
                r_mux_sel = 1'b1;

                if(counter >= 6'd32 || (sparse_on && b_reg == 32'd0)) next_state = s3;

                if(b_lsb) begin
                    add_mux_sel = 1'b1;
                    r_en = 1'b1;
                end

            end

        s3: begin //done state
                state_done = 1'b1; 
                ostream_val = 1'b1;
                if(ostream_rdy) begin
                    next_state = s1;
                end
            end
        endcase
    end

endmodule