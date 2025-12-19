`timescale 1ns / 1ps

module clock_divider (
    input  wire clk_in,
    input  wire rst,
    output reg  clk_out
);

    reg [25:0] count;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count   <= 0;
            clk_out <= 0;
        end else if (count == 26'd50_000_000) begin
            count   <= 0;
            clk_out <= ~clk_out;
        end else begin
            count <= count + 1'b1;
        end
    end

endmodule
