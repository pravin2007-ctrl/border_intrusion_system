`timescale 1ns / 1ps

module tb_border_intrusion_advanced;

    // =========================
    // DUT signals
    // =========================
    reg clk;
    reg rst;
    reg arm;
    reg [3:0] zone;

    wire safe_led;
    wire alert_led;
    wire high_alert_led;
    wire tamper_led;
    wire [3:0] zone_led;

    // =========================
    // DUT instance
    // =========================
    border_intrusion_advanced dut (
        .clk(clk),
        .rst(rst),
        .arm(arm),
        .zone(zone),
        .safe_led(safe_led),
        .alert_led(alert_led),
        .high_alert_led(high_alert_led),
        .tamper_led(tamper_led),
        .zone_led(zone_led)
    );

    // =========================
    // Clock (10 ns period)
    // =========================
    always #5 clk = ~clk;

    // =========================
    // TASKS
    // =========================
    task reset_sys;
    begin
        rst  = 1;
        arm  = 0;
        zone = 0;
        #40;
        rst  = 0;
        #40;
    end
    endtask

    task arm_on;
    begin
        arm = 1;
        #40;
    end
    endtask

    task arm_off;
    begin
        arm = 0;
        #40;
    end
    endtask

    task single_zone(input [3:0] z);
    begin
        zone = z;   #100;
        zone = 0;   #100;
    end
    endtask

    task dynamic_escalation;
    begin
        zone = 4'b0001;  #100;   // ALERT
        zone = 4'b0011;  #100;   // HIGH ALERT
        zone = 4'b0001;  #100;   // ALERT
        zone = 4'b0000;  #100;   // SAFE
    end
    endtask

    task multi_zone(input [3:0] z);
    begin
        zone = z;   #120;
        zone = 0;   #120;
    end
    endtask

    task tamper_test(input [3:0] z);
        integer i;
    begin
        zone = z;
        for (i = 0; i < 10; i = i + 1)
            #20;          // hold constant
        zone = 0;
        #120;
    end
    endtask

    // =========================
    // TEST SEQUENCE
    // =========================
    initial begin
        clk  = 0;
        rst  = 0;
        arm  = 0;
        zone = 0;

        // -------------------------
        // 1️⃣ DISARMED MODE
        // -------------------------
        zone = 4'b1111;  // should be ignored
        #100;

        // -------------------------
        // 2️⃣ RESET & ARM
        // -------------------------
        reset_sys;
        arm_on;

        // -------------------------
        // 3️⃣ SINGLE ZONE TESTS
        // -------------------------
        single_zone(4'b0001);
        single_zone(4'b0010);
        single_zone(4'b0100);
        single_zone(4'b1000);

        // -------------------------
        // 4️⃣ DYNAMIC ESCALATION
        // -------------------------
        dynamic_escalation;

        // -------------------------
        // 5️⃣ MULTI-ZONE ATTACKS
        // -------------------------
        multi_zone(4'b0011);
        multi_zone(4'b0110);
        multi_zone(4'b1100);
        multi_zone(4'b1111);

        // -------------------------
        // 6️⃣ TAMPER DETECTION
        // -------------------------
        tamper_test(4'b0001);
        tamper_test(4'b0100);

        // -------------------------
        // 7️⃣ ARM OFF DURING ALERT
        // -------------------------
        zone = 4'b0010;
        #60;
        arm_off;         // should force SAFE
        zone = 0;
        #100;

        // -------------------------
        // 8️⃣ RESET DURING HIGH ALERT
        // -------------------------
        arm_on;
        zone = 4'b1111;
        #60;
        rst = 1;
        #20;
        rst = 0;
        zone = 0;
        #100;

        // -------------------------
        // END SIMULATION
        // -------------------------
        #200;
        $finish;
    end

endmodule
