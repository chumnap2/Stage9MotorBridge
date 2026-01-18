#!/usr/bin/env python3
"""
auto_ramp_client.py
Automatically ramps Stage9 motor safely
"""

import socket
import threading
import time

HOST = "127.0.0.1"
PORT = 12345
running = True

def receive_telemetry(sock):
    global running
    while running:
        try:
            data = sock.recv(1024)
            if not data:
                break
            print("[SERVER]", data.decode().strip())
        except:
            break

def send(sock, msg):
    sock.sendall((msg+"\n").encode())
    print("➡️", msg)

def main():
    global running
    with socket.create_connection((HOST, PORT)) as sock:
        print(f"✅ Connected to server {HOST}:{PORT}")
        rx = threading.Thread(target=receive_telemetry, args=(sock,), daemon=True)
        rx.start()

        # Enable motor
        send(sock, "enable")
        time.sleep(0.1)

        # Ramp up 0 -> 0.5
        for i in range(11):
            duty = round(i*0.05, 2)
            send(sock, f"set_duty {duty}")
            time.sleep(0.5)

        # Hold max duty
        time.sleep(1.0)

        # Ramp down 0.5 -> 0
        for i in range(10, -1, -1):
            duty = round(i*0.05, 2)
            send(sock, f"set_duty {duty}")
            time.sleep(0.5)

        # Disable motor
        send(sock, "disable")
        running = False
        time.sleep(0.1)
        print("🔒 Auto-ramp test complete")

if __name__ == "__main__":
    main()
