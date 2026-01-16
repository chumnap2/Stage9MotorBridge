#!/usr/bin/env python3
"""
motor_spin_minimal_nov20.py
Safe real VESC motor spin (Stage8-proven)
"""

import sys
import time
from vescminimal_nov20 import VESC

# -----------------------------
# Configuration
# -----------------------------
VESC_PORT = "/dev/ttyACM0"
MAX_SAFE_DUTY = 0.5

# -----------------------------
# Parse duty
# -----------------------------
try:
    duty = float(sys.argv[1])
except (IndexError, ValueError):
    duty = 0.0

# Safety clamp
duty = max(-MAX_SAFE_DUTY, min(duty, MAX_SAFE_DUTY))

print(f"➡️ Requested duty: {duty}")

# -----------------------------
# Connect to VESC (Stage8 way)
# -----------------------------
try:
    vesc = VESC(VESC_PORT)
    print(f"🔌 Connected to VESC on {VESC_PORT}")
except Exception as e:
    print(f"❌ VESC open failed: {e}")
    sys.exit(1)

# -----------------------------
# Send duty
# -----------------------------
try:
    pkt = vesc.set_duty_cycle(duty)
    print("📦 Packet sent:", pkt.hex())
except Exception as e:
    print(f"❌ Duty send failed: {e}")
    sys.exit(1)

time.sleep(0.05)
