#!/usr/bin/env python3
"""
motor_client_stage9.py
Client for Stage9MotorBridge Julia TCP server
"""

import socket
import threading
import time

HOST = "127.0.0.1"
PORT = 12345

running = True

def receive_responses(sock):
    """Receive ACKs and server messages"""
    global running
    while running:
        try:
            data = sock.recv(1024)
            if not data:
                print("[INFO] Server closed connection.")
                break
            print("[SERVER]", data.decode().strip())
        except Exception as e:
            print("[ERROR] Receiver:", e)
            break

def send(sock, msg):
    print("➡️ ", msg)
    sock.sendall((msg + "\n").encode())

def main():
    global running

    with socket.create_connection((HOST, PORT)) as sock:
        print(f"✅ Connected to Stage9 server at {HOST}:{PORT}")

        rx = threading.Thread(
            target=receive_responses,
            args=(sock,),
            daemon=True
        )
        rx.start()

        print("\nCommands:")
        print("  enable")
        print("  disable")
        print("  duty <value>   (example: duty 0.25)")
        print("  ping")
        print("  quit\n")

        try:
            while True:
                line = input("> ").strip().lower()
                if not line:
                    continue

                parts = line.split()

                if parts[0] in ("quit", "exit"):
                    send(sock, "DISABLE")
                    break

                elif parts[0] == "enable":
                    send(sock, "ENABLE")

                elif parts[0] == "disable":
                    send(sock, "DISABLE")

                elif parts[0] == "ping":
                    send(sock, "PING")

                elif parts[0] == "duty":
                    if len(parts) != 2:
                        print("[WARN] Usage: duty <value>")
                        continue
                    try:
                        val = float(parts[1])
                        if not (0.0 <= val <= 1.0):
                            print("[WARN] Duty must be 0.0–1.0")
                            continue
                        send(sock, f"SET_DUTY {val}")
                    except ValueError:
                        print("[WARN] Invalid number")

                else:
                    print("[WARN] Unknown command")

        except KeyboardInterrupt:
            print("\n[INFO] Ctrl+C")

        finally:
            running = False
            time.sleep(0.1)
            print("🔒 Client closed")

if __name__ == "__main__":
    main()
