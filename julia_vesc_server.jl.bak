#!/usr/bin/env julia
using Sockets
using Dates

# -------------------------------------------------
# Configuration
# -------------------------------------------------
PORT = 12345
PROJECT_ROOT = "/home/chumnap/fprime-motorbridge/Projects/Stage9Project"
DEPLOYMENT_NAME = "Stage9MotorBridgeDeployment"

# -------------------------------------------------
# Launch F´ GDS (background, non-blocking)
# -------------------------------------------------
println("🚀 Launching F´ GDS...")

try
    run(
        Cmd(`fprime-gds --app $DEPLOYMENT_NAME`, dir = PROJECT_ROOT);
        wait = false
    )
    println("🎉 F´ GDS launched")
catch e
    println("⚠️ Failed to launch F´ GDS:")
    println(e)
end

# -------------------------------------------------
# Start TCP Server (Julia 1.10 safe)
# -------------------------------------------------
server = try
    listen(PORT)
catch e
    println("❌ Failed to bind TCP port $PORT")
    println("   $e")
    println("⚠️ Check for existing process using:")
    println("   lsof -i :$PORT")
    exit(1)
end

println("🟢 Julia VESC server listening on port $PORT")

# -------------------------------------------------
# Accept client
# -------------------------------------------------
sock = accept(server)
println("🔌 Client connected")

# -------------------------------------------------
# Motor state (simulated)
# -------------------------------------------------
rpm     = 0
duty    = 0.0
current = 0.0
volt    = 24.0
fault   = 0

# -------------------------------------------------
# Main loop
# -------------------------------------------------
while true
    try
        if bytesavailable(sock) > 0
            cmd = strip(readline(sock))
            println("📥 CMD: $cmd")

            if startswith(cmd, "duty=")
                duty = parse(Float64, split(cmd, "=")[2])
            elseif startswith(cmd, "current=")
                current = parse(Float64, split(cmd, "=")[2])
            elseif cmd == "stop"
                duty = 0.0
                current = 0.0
            elseif cmd == "fault"
                fault = 1
            elseif cmd == "clear_fault"
                fault = 0
            else
                println("⚠️ Unknown command")
            end
        end

        rpm = round(Int, duty * 1000)

        println(
            sock,
            "rpm=$rpm duty=$duty current=$current volt=$volt fault=$fault time=$(now())"
        )

        sleep(0.05)  # 20 Hz

    catch e
        println("❌ Client disconnected: $e")
        close(sock)

        println("⏳ Waiting for client reconnect...")
        sock = accept(server)
        println("🔌 Client reconnected")
    end
end
