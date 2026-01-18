#!/usr/bin/env julia
using Sockets
using Dates

# -----------------------------
# Configuration
# -----------------------------
const HOST = ip"127.0.0.1"
const PORT = 12345
PROJECT_ROOT = "/home/chumnap/fprime-motorbridge/Projects/Stage9Project"
DEPLOYMENT_NAME = "Stage9MotorBridgeDeployment"

# -----------------------------
# Launch F´ GDS (optional)
# -----------------------------
println("🚀 Launching F´ GDS...")
try
    run(Cmd(`fprime-gds --app $DEPLOYMENT_NAME`, dir=PROJECT_ROOT); wait=false)
    println("🎉 F´ GDS launched")
catch e
    println("⚠️ Failed to launch F´ GDS: $e")
end

# -----------------------------
# Motor state
# -----------------------------
global motor_enabled = false
global duty = 0.0
global rpm = 0
global current = 0.0
global volt = 24.0
global fault = 0
global sock::Union{TCPSocket,Nothing} = nothing  # client socket

# -----------------------------
# Start TCP server
# -----------------------------
server = try
    listen(HOST, PORT)
catch e
    println("❌ Failed to bind TCP port $PORT: $e")
    exit(1)
end

println("🟢 Julia VESC server listening on port $PORT")

# -----------------------------
# Helper: handle commands
# -----------------------------
function handle_command(cmd::String)
    cmd_clean = strip(lowercase(cmd))
    println("📥 Received command: '$cmd_clean'")

    if cmd_clean == "enable"
        global motor_enabled = true
        println("✅ Motor ENABLE")

    elseif cmd_clean == "disable"
        global motor_enabled = false
        global duty = 0.0
        println("⚠️ Motor DISABLE")

    elseif startswith(cmd_clean, "set_duty") || startswith(cmd_clean, "duty")
        parts = split(cmd_clean, r"[= ]", limit=2)
        if length(parts) == 2
            val = try parse(Float64, parts[2]) catch e
                println("⚠️ Invalid duty value: $(parts[2])")
                return
            end
            global duty = motor_enabled ? clamp(val, 0.0, 1.0) : 0.0
            println("🎚️ Duty set to $duty")
        else
            println("⚠️ Malformed duty command: $cmd")
        end

    elseif cmd_clean == "stop"
        global duty = 0.0
        global current = 0.0
        println("⏹️ Motor STOPPED")

    elseif cmd_clean == "fault"
        global fault = 1
        println("⚠️ Fault triggered")

    elseif cmd_clean == "clear_fault"
        global fault = 0
        println("✅ Fault cleared")

    else
        println("⚠️ Unknown command: $cmd")
    end
end

# -----------------------------
# Main loop
# -----------------------------
while true
    # Accept client if none connected
    if sock === nothing
        println("⏳ Waiting for client connection...")
        try
            global sock = accept(server)
            println("🔌 Client connected")
        catch e
            println("❌ Accept failed: $e")
            sleep(0.5)
            continue
        end
    end

    # -----------------------------
    # Read commands if available
    # -----------------------------
    try
        # Use blocking readline to safely get commands
        cmd = readline(sock)
        handle_command(cmd)
    catch e
        println("❌ Client disconnected or read error: $e")
        global sock = nothing
        continue
    end

    # -----------------------------
    # Update motor state
    # -----------------------------
    global rpm = round(Int, duty * 1000)

    # -----------------------------
    # Send telemetry safely
    # -----------------------------
    if sock !== nothing
        try
            println(sock, "rpm=$rpm duty=$duty current=$current volt=$volt fault=$fault time=$(now())")
        catch e
            println("⚠️ Telemetry send failed: $e")
            global sock = nothing
        end
    end

    sleep(0.05)  # 20 Hz
end
