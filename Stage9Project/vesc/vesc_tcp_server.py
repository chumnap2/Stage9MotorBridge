#!/usr/bin/env python3
"""
Stage 9 – Python VESC TCP Server (SAFE MODE)

- Opens VESC over USB
- Listens on localhost TCP
- NO motor motion commands
"""

import socket
import threading
import sys
import time

# -------------------------
# Configuration
# -------------------------
HOST = "127.0.0.1"
PORT = 23456            # Python side port
VESC_PORT = "/dev/ttyACM0"
VESC_BAUD = 115200

# -------------------------
# Load VESC library
# -------------------------
try:
    from pyvesc.VESC import VESC
except Exception as e:
    print("❌ Failed to import pyvesc:", e)
    sys.exit(1)

# -------------------------
# Open VESC (SAFE)
# -------------------------
try:
    vesc = VESC(serial_port=VESC_PORT, baudrate=VESC_BAUD)
    print(f"✅ VESC opened on {VESC_PORT}")
except Exception as e:
    print("❌ Failed to open VESC:", e)
    sys.exit(1)

# -------------------------
# Client handler
# -------------------------
def handle_client(conn, addr):
    print(f"✅ Client connected: {addr}")
    conn.sendall(b"HELLO VESC\n")

    try:
        while True:
            data = conn.recv(1024)
            if not data:
                break

            line = data.decode().strip()
            print("📩 Received:", line)

            if line == "PING":
                conn.sendall(b"PONG\n")

            elif line == "STATUS":
                # No motor motion here
                conn.sendall(b"STATUS OK SAFE_MODE\n")

            else:
                conn.sendall(b"ERR UNKNOWN_CMD\n")

    except Exception as e:
        print("⚠️ Client error:", e)

    finally:
        print(f"ℹ️ Client disconnected: {addr}")
        conn.close()

# -------------------------
# TCP server
# -------------------------
def tcp_server():
    print(f"🚀 Python VESC TCP server on {HOST}:{PORT}")
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen()

        while True:
            conn, addr = s.accept()
            t = threading.Thread(
                target=handle_client,
                args=(conn, addr),
                daemon=True
            )
            t.start()

# -------------------------
# Main
# -------------------------
if __name__ == "__main__":
    tcp_server()
