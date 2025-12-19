`timescale 1ns / 1ps

module top_border_intrusion_fpga (
    input  wire       clk,
    input  wire       rst,
    input  wire       arm,
    input  wire [3:0] zone,

    output wire       safe_led,
    output wire       alert_led,
    output wire       high_alert_led,
    output wire       tamper_led,
    output wire [3:0] zone_led
);
wire slow_clk;

    clock_divider u_clk_div (
        .clk_in (clk),
        .rst    (rst),
        .clk_out(slow_clk)
    );

    

    border_intrusion_advanced u_core (
        .clk            (slow_clk),
        .rst            (rst),
        .arm            (arm),
        .zone           (zone),
        .safe_led       (safe_led),
        .alert_led      (alert_led),
        .high_alert_led (high_alert_led),
        .tamper_led     (tamper_led),
        .zone_led       (zone_led)
    );

endmodule

