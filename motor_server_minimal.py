#!/usr/bin/env python3
import sys
import serial
import time

VESC_PORT = "/dev/ttyACM0"
BAUD = 115200

# open serial to VESC
ser = serial.Serial(VESC_PORT, BAUD)
time.sleep(0.1)

print("Python motor server started", flush=True)

def send_duty(duty):
    duty = max(0.0, min(duty, 0.2))  # clamp
    duty_int = int(duty * 1e6)        # minimal example
    packet = bytearray([0x02, 0x05, 0x05, 0, 0, 0, 0, 0x03])
    ser.write(packet)
    ser.flush()
    print(f"📦 Duty sent: {duty}", flush=True)

# main loop reading stdin
for line in sys.stdin:
    try:
        val = float(line.strip())
        send_duty(val)
    except Exception as e:
        print(f"⚠️ Error: {e}", flush=True)
