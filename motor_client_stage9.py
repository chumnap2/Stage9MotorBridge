import socket

HOST = "127.0.0.1"
PORT = 12345

with socket.create_connection((HOST, PORT)) as sock:
    print(f"✅ Connected to server at {HOST}:{PORT}")

    while True:
        line = input("> ").strip()
        if not line:
            continue

        # send command
        sock.sendall((line + "\n").encode())

        # read **one** response
        data = sock.recv(1024)
        print("[SERVER]", data.decode().strip())

