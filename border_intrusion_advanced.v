`timescale 1ns / 1ps

module border_intrusion_advanced (
    input  wire       clk,
    input  wire       rst,
    input  wire       arm,
    input  wire [3:0] zone,

    output reg        safe_led,
    output reg        alert_led,
    output reg        high_alert_led,
    output reg        tamper_led,
    output reg [3:0]  zone_led
);

    // ==============================
    // FSM STATES
    // ==============================
    parameter IDLE      = 2'b00;
    parameter MONITOR   = 2'b01;
    parameter ALERT     = 2'b10;
    parameter HIGHALERT = 2'b11;

    reg [1:0] state, next_state;

    // ==============================
    // ZONE PRIORITY
    // ==============================
    reg [1:0] zone_detected;
    reg       zone_valid;

    always @(*) begin
        zone_valid = (zone != 4'b0000);
        if      (zone[3]) zone_detected = 2'd3;
        else if (zone[2]) zone_detected = 2'd2;
        else if (zone[1]) zone_detected = 2'd1;
        else              zone_detected = 2'd0;
    end

    // ==============================
    // TAMPER DETECTION (TIME BASED)
    // ==============================
    reg [3:0] zone_prev;
    reg [3:0] stable_count;
    reg       tamper_detected;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            zone_prev        <= 4'b0000;
            stable_count    <= 4'b0000;
            tamper_detected <= 1'b0;
        end else if (!arm) begin
            // ignore sensors when disarmed
            zone_prev        <= 4'b0000;
            stable_count    <= 4'b0000;
            tamper_detected <= 1'b0;
        end else begin
            if (zone == zone_prev && zone_valid)
                stable_count <= stable_count + 1'b1;
            else
                stable_count <= 4'b0000;

            tamper_detected <= (stable_count >= 4'd8);
            zone_prev <= zone;
        end
    end

    // ==============================
    // FSM STATE REGISTER
    // ==============================
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else if (!arm)
            state <= IDLE;   // force SAFE when disarmed
        else
            state <= next_state;
    end

    // ==============================
    // FSM NEXT STATE LOGIC (ARM GATED)
    // ==============================
    always @(*) begin
        next_state = IDLE;  // default SAFE

        if (arm) begin
            next_state = state;

            case (state)
                IDLE:
                    next_state = MONITOR;

                MONITOR: begin
                    if (tamper_detected)
                        next_state = HIGHALERT;
                    else if (zone_valid && ((zone & (zone - 1)) != 0))
                        next_state = HIGHALERT;
                    else if (zone_valid)
                        next_state = ALERT;
                end

                ALERT: begin
                    if (zone_valid && ((zone & (zone - 1)) != 0))
                        next_state = HIGHALERT;
                    else if (!zone_valid)
                        next_state = MONITOR;
                end

                HIGHALERT: begin
                    if (tamper_detected)
                        next_state = HIGHALERT;
                    else if (zone_valid && ((zone & (zone - 1)) == 0))
                        next_state = ALERT;
                    else if (!zone_valid)
                        next_state = MONITOR;
                end
            endcase
        end
    end

    // ==============================
    // OUTPUT LOGIC (ARM GATED)
    // ==============================
    always @(*) begin
        // default OFF
        safe_led       = 1'b0;
        alert_led      = 1'b0;
        high_alert_led = 1'b0;
        tamper_led     = 1'b0;
        zone_led       = 4'b0000;

        if (!arm) begin
            // DISARMED → SAFE ONLY
            safe_led = 1'b1;
        end else begin
            case (state)
                IDLE, MONITOR: begin
                    if (!zone_valid)
                        safe_led = 1'b1;
                end

                ALERT: begin
                    if (zone_valid) begin
                        alert_led = 1'b1;
                        zone_led[zone_detected] = 1'b1;
                    end
                end

                HIGHALERT: begin
                    if (zone_valid || tamper_detected) begin
                        high_alert_led = 1'b1;
                        tamper_led     = tamper_detected;
                        if (zone_valid)
                            zone_led[zone_detected] = 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
