#!/usr/bin/env julia
using Sockets
using Dates

# -----------------------------
# Configuration
# -----------------------------
const HOST = ip"127.0.0.1"
const PORT = 12345
const MAX_SAFE_DUTY = 0.5

# -----------------------------
# Motor state
# -----------------------------
global motor_enabled = false
global duty = 0.0
global rpm = 0
global current = 0.0
global volt = 24.0
global fault = 0
global sock::Union{TCPSocket,Nothing} = nothing

# -----------------------------
# Safe Python motor spin
# -----------------------------
function set_motor_safe(duty::Float64)
    duty = clamp(duty, 0.0, MAX_SAFE_DUTY)  # safety clamp
    try
        run(`python3 motor_spin_minimal_nov20.py $duty`)
    catch e
        println("⚠️ Failed to run Python motor spin: $e")
    end
end

# -----------------------------
# TCP Server
# -----------------------------
server = listen(HOST, PORT)
println("🟢 Server listening on $HOST:$PORT")

# -----------------------------
# Command handler
# -----------------------------
function handle_command(cmd::String)
    cmd_clean = strip(lowercase(cmd))

    if cmd_clean == "enable"
        global motor_enabled = true
        println("✅ Motor ENABLE")
        set_motor_safe(duty)

    elseif cmd_clean == "disable"
        global motor_enabled = false
        global duty = 0.0
        println("⚠️ Motor DISABLE")
        set_motor_safe(0.0)

    elseif startswith(cmd_clean, "set_duty") || startswith(cmd_clean, "duty")
        parts = split(cmd_clean, r"[= ]", limit=2)
        if length(parts) == 2
            val = try parse(Float64, parts[2]) catch e
                println("⚠️ Invalid duty: $(parts[2])")
                return
            end
            global duty = motor_enabled ? clamp(val, 0.0, MAX_SAFE_DUTY) : 0.0
            println("🎚️ Duty set to $duty")
            set_motor_safe(duty)
        else
            println("⚠️ Malformed duty command: $cmd_clean")
        end

    elseif cmd_clean == "stop"
        global duty = 0.0
        println("⏹️ Motor STOPPED")
        set_motor_safe(0.0)

    elseif cmd_clean == "fault"
        global fault = 1
        println("⚠️ Fault triggered")

    elseif cmd_clean == "clear_fault"
        global fault = 0
        println("✅ Fault cleared")

    else
        println("⚠️ Unknown command: $cmd_clean")
    end
end

# -----------------------------
# Main loop
# -----------------------------
while true
    # Accept client if none
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

    try
        if bytesavailable(sock) > 0
            cmd = strip(readline(sock))
            println("📥 CMD: $cmd")
            handle_command(cmd)
        end

        # Update simulated RPM based on duty
        global rpm = round(Int, duty * 1000)

        # Send telemetry
        println(sock,
            "rpm=$rpm duty=$duty current=$current volt=$volt fault=$fault time=$(now())"
        )

        sleep(0.05)  # 20 Hz
    catch e
        println("❌ Client disconnected: $e")
        close(sock)
        global sock = nothing
    end
end
