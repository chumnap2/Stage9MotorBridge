#!/usr/bin/env python3
"""
Stage9 VESC TCP Server (SAFE MODE with min duty 0.5)
- Enable/disable/stop safety
- Duty clamped ±0.5..1.0
- Async TCP client handling
"""

import sys
import socket
import threading
from pathlib import Path

# -------------------------------------------------
# Vendored VESC path injection
# -------------------------------------------------
VENDOR_DIR = Path(__file__).parent / "vendor"
sys.path.insert(0, str(VENDOR_DIR))

from vescminimal_nov20 import VESC

# -------------------------------------------------
# Configuration
# -------------------------------------------------
HOST = "127.0.0.1"
PORT = 12345
SERIAL_PORT = "/dev/ttyACM0"

# -------------------------------------------------
# Open VESC (SAFE)
# -------------------------------------------------
vesc = VESC(SERIAL_PORT)
vesc.set_duty_cycle(0.0)
print("✅ VESC opened (SAFE MODE, duty=0)")

# -------------------------------------------------
# Safety state
# -------------------------------------------------
enabled = False
last_duty = 0.0
MIN_DUTY = 0.5  # minimum duty for spinning
lock = threading.Lock()  # thread-safe access

# -------------------------------------------------
# Emergency stop / disable
# -------------------------------------------------
def force_stop():
    global enabled, last_duty
    with lock:
        enabled = False
        last_duty = 0.0
        vesc.set_duty_cycle(0.0)

# -------------------------------------------------
# Async duty sender
# -------------------------------------------------
def duty_sender():
    while True:
        with lock:
            if enabled:
                # Clamp duty to ±MIN_DUTY..1.0
                duty = max(MIN_DUTY, min(abs(last_duty), 1.0))
                if last_duty < 0:
                    duty *= -1
                vesc.set_duty_cycle(duty)
            else:
                vesc.set_duty_cycle(0.0)
        # 50 ms loop
        threading.Event().wait(0.05)

threading.Thread(target=duty_sender, daemon=True).start()

# -------------------------------------------------
# TCP Server
# -------------------------------------------------
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen()
print(f"🚀 VESC TCP server listening on {HOST}:{PORT}")

# -------------------------------------------------
# Client handler
# -------------------------------------------------
def handle_client(conn, addr):
    global enabled, last_duty
    print(f"✅ Client connected: {addr}")
    conn.sendall(b"HELLO VESC SAFE_MODE\n")

    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break

            # sanitize input
            line = data.decode(errors="ignore").strip().split("→")[0].split("#")[0].strip()
            if not line:
                continue

            parts = line.split(maxsplit=1)
            cmd = parts[0].lower()

            # safe float parsing
            try:
                value = float(parts[1]) if len(parts) == 2 else 0.0
            except ValueError:
                value = 0.0

            with lock:
                if cmd == "enable":
                    enabled = True
                    conn.sendall(b"ACK ENABLED\n")

                elif cmd == "disable":
                    enabled = False
                    last_duty = 0.0
                    vesc.set_duty_cycle(0.0)
                    conn.sendall(b"ACK DISABLED\n")

                elif cmd == "stop":
                    force_stop()
                    conn.sendall(b"ACK STOPPED\n")

                elif cmd == "duty":
                    if enabled:
                        # Only apply if enabled
                        last_duty = value
                        conn.sendall(f"ACK DUTY {last_duty:.4f}\n".encode())
                    else:
                        conn.sendall(b"ERR NOT_ENABLED\n")

                elif cmd == "ping":
                    conn.sendall(b"ACK PING\n")

                else:
                    conn.sendall(b"ERR UNKNOWN COMMAND\n")

    except Exception as e:
        print(f"❌ Client error {addr}: {e}")
    finally:
        conn.close()
        print(f"🔌 Client disconnected: {addr}")

# -------------------------------------------------
# Accept clients (threaded)
# -------------------------------------------------
while True:
    conn, addr = server.accept()
    threading.Thread(
        target=handle_client,
        args=(conn, addr),
        daemon=True
    ).start()
