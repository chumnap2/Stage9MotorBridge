#!/usr/bin/env python3
"""
Stage 9 – Python VESC TCP Server (HARD SAFE MODE)

Safety rules enforced:
- enabled flag REQUIRED to move
- STOP always forces duty = 0 immediately
- duty ignored unless enabled
- duty clamped to ±0.05
"""

import sys
import socket
import threading
import time
from pathlib import Path

# -------------------------------------------------
# Vendored VESC module (NO pyvesc dependency)
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

MAX_DUTY = 0.05          # HARD SAFETY LIMIT
SEND_PERIOD = 0.05      # 20 Hz

# -------------------------------------------------
# Global state (guarded by lock)
# -------------------------------------------------
enabled = False
last_duty = 0.0
state_lock = threading.Lock()
running = True

# -------------------------------------------------
# Open VESC (NO MOTION HERE)
# -------------------------------------------------
vesc = VESC(SERIAL_PORT)
print("✅ VESC opened (SAFE MODE, duty locked at 0.0)")

# -------------------------------------------------
# Async duty sender (HARD SAFETY LOOP)
# -------------------------------------------------
def duty_sender():
    global last_duty, enabled

    while running:
        with state_lock:
            if enabled:
                duty = max(-MAX_DUTY, min(MAX_DUTY, last_duty))
            else:
                duty = 0.0

        try:
            vesc.set_duty(duty)
        except Exception as e:
            print("❌ VESC send error:", e)

        time.sleep(SEND_PERIOD)

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
    conn.sendall(b"HELLO VESC SAFE MODE\n")

    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break

            line = data.decode(errors="ignore").strip()
            if not line:
                continue

            print("⬅️  CMD:", line)
            parts = line.split(maxsplit=1)
            cmd = parts[0].lower()

            with state_lock:

                if cmd == "enable":
                    enabled = True
                    conn.sendall(b"ACK ENABLED\n")

                elif cmd == "disable":
                    enabled = False
                    last_duty = 0.0
                    conn.sendall(b"ACK DISABLED\n")

                elif cmd == "stop":
                    enabled = False
                    last_duty = 0.0
                    conn.sendall(b"ACK STOPPED\n")

                elif cmd == "duty":
                    if not enabled:
                        conn.sendall(b"ERR NOT_ENABLED\n")
                        continue

                    try:
                        val = float(parts[1])
                    except Exception:
                        conn.sendall(b"ERR BAD_VALUE\n")
                        continue

                    last_duty = max(-MAX_DUTY, min(MAX_DUTY, val))
                    conn.sendall(
                        f"ACK DUTY {last_duty:.4f}\n".encode()
                    )

                elif cmd == "ping":
                    conn.sendall(b"PONG\n")

                else:
                    conn.sendall(b"ERR UNKNOWN_CMD\n")

    except Exception as e:
        print("⚠️ Client error:", e)

    finally:
        print(f"🔌 Client disconnected: {addr}")
        conn.close()

# -------------------------------------------------
# Accept loop
# -------------------------------------------------
try:
    while True:
        conn, addr = server.accept()
        threading.Thread(
            target=handle_client,
            args=(conn, addr),
            daemon=True
        ).start()
except KeyboardInterrupt:
    print("\n🛑 Shutting down safely...")
finally:
    running = False
    server.close()
