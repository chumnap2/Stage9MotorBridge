#!/usr/bin/env julia
using Sockets
using Dates
#using Base.Processes  # for run / pipeline

# =============================
# Configuration
# =============================
const HOST = ip"127.0.0.1"
const PORT = 12345
const MAX_SAFE_DUTY = 0.2   # HARD SAFETY LIMIT
const TELEMETRY_HZ = 20

# =============================
# Safety state (INTENT only)
# =============================
global armed = false
global requested_duty = 0.0

# =============================
# TCP socket
# =============================
global sock::Union{TCPSocket,Nothing} = nothing

# =============================
# Safe Python motor call
# =============================
function set_motor_safe(duty::Float64)
    duty = clamp(duty, 0.0, MAX_SAFE_DUTY)
    try
        run(`python3 motor_spin_minimal_nov20.py $duty`)
    catch e
        println("⚠️ Python motor call failed: $e")
    end
end

# =============================
# Start TCP server
# =============================
server = listen(HOST, PORT)
println("🟢 Julia VESC TCP server listening on $HOST:$PORT")

# =============================
# Main loop
# =============================
while true
    # -------------------------
    # Accept client if none
    # -------------------------
    if sock === nothing
        println("⏳ Waiting for client connection...")
        try
            global sock = accept(server)
            println("🔌 Client connected")
        catch e
            println("❌ Accept failed: $e")
            sleep(1)
            continue
        end
    end

    # -------------------------
    # Try reading command (blocking)
    # -------------------------
    try
        cmd = strip(lowercase(readline(sock)))  # BLOCK until line arrives
        println("[SERVER] CMD: $cmd")

        if cmd == "enable"
            println("[SERVER] enable received (idle)")

        elseif cmd == "arm"
            global armed = true
            if requested_duty == 0.0
                global requested_duty = 0.05   # small initial duty when arming
            end
            println("[SERVER] ARMED → starting duty=$requested_duty")

        elseif cmd == "disarm"
            global armed = false
            global requested_duty = 0.0
            set_motor_safe(0.0)   # 🔴 IMMEDIATE HARD STOP
            println("[SERVER] DISARMED → duty forced to 0")

        elseif startswith(cmd, "duty")
            parts = split(cmd)
            if length(parts) == 2
                val = try parse(Float64, parts[2]) catch
                    println("[SERVER] invalid duty value")
                    continue
                end
                global requested_duty = clamp(val, 0.0, MAX_SAFE_DUTY)
                println("[SERVER] duty requested = $requested_duty")
            else
                println("[SERVER] malformed duty command")
            end

        else
            println("[SERVER] unknown command")
        end

    catch e
        # -------------------------
        # Client disconnected or EOF
        # -------------------------
        println("❌ Client disconnected: $e")
        global armed = false
        global requested_duty = 0.0
        set_motor_safe(0.0)  # 🔴 FAIL-SAFE

        try close(sock) catch end
        global sock = nothing
        sleep(1)
        continue
    end

    # -------------------------
    # APPLY DUTY (ONLY HERE)
    # -------------------------
    if armed
        set_motor_safe(requested_duty)
    else
        set_motor_safe(0.0)
    end

    # -------------------------
    # Telemetry
    # -------------------------
    if sock !== nothing
        try
            println(sock, "armed=$armed duty=$requested_duty time=$(now())")
        catch
            # Ignore write errors; disconnect will handle stop
        end
    end

    sleep(1/TELEMETRY_HZ)  # 20 Hz
end
