#!/usr/bin/env python3
"""
motor_client_auto_run.py
Auto-enable and ramp test for Stage9MotorBridge
"""

import socket
import threading
import time

HOST = "127.0.0.1"
PORT = 12345
running = True

def receive_telemetry(sock):
    """Continuously print server telemetry."""
    global running
    while running:
        try:
            data = sock.recv(1024)
            if not data:
                print("[INFO] Server closed connection")
                break
            print("[SERVER]", data.decode().strip())
        except Exception as e:
            print("[ERROR] Receiver:", e)
            break

def send(sock, msg):
    """Send command to server."""
    print("➡️", msg)
    sock.sendall((msg + "\n").encode())

def main():
    global running

    with socket.create_connection((HOST, PORT)) as sock:
        print(f"✅ Connected to Stage9 server at {HOST}:{PORT}")

        # Start telemetry thread
        rx = threading.Thread(target=receive_telemetry, args=(sock,), daemon=True)
        rx.start()

        # Auto-enable motor
        send(sock, "enable")
        time.sleep(0.1)

        # Ramp duty 0 -> 1
        for i in range(21):
            duty = round(i * 0.05, 2)  # 0.0, 0.05, ..., 1.0
            send(sock, f"set_duty {duty}")
            time.sleep(0.2)  # 5 Hz ramp

        # Hold max duty for 1 second
        time.sleep(1.0)

        # Ramp duty 1 -> 0
        for i in range(20, -1, -1):
            duty = round(i * 0.05, 2)
            send(sock, f"set_duty {duty}")
            time.sleep(0.2)

        # Disable motor
        send(sock, "disable")
        running = False
        time.sleep(0.1)
        print("🔒 Auto ramp test finished")

if __name__ == "__main__":
    main()
