#!/usr/bin/env julia
using Sockets
using Dates
using Printf

# -------------------------
# Configuration
# -------------------------
PORT = 12345
PROJECT_ROOT = "/home/chumnap/fprime-motorbridge/Projects/Stage9Project"
DEPLOYMENT_NAME = "Stage9MotorBridgeDeployment"
BUILD_DIR = joinpath(PROJECT_ROOT, "build-fprime-automatic-$DEPLOYMENT_NAME")
DEPLOYMENT_BIN = joinpath(BUILD_DIR, "bin", DEPLOYMENT_NAME)
DEPLOYMENT_YAML = joinpath(BUILD_DIR, "$DEPLOYMENT_NAME.yaml")

# -------------------------
# Launch F´ GDS (YAML preferred, binary fallback)
# -------------------------
println("🚀 Launching F´ GDS...")

gds_launched = false

if isfile(DEPLOYMENT_YAML)
    println("ℹ️ Found deployment YAML: $DEPLOYMENT_YAML")
    @async try
        run(`fprime-gds --app $DEPLOYMENT_YAML`)
        gds_launched = true
    catch e
        println("❌ Failed to launch GDS with YAML: $e")
    end
elseif isfile(DEPLOYMENT_BIN)
    println("ℹ️ Found deployment binary: $DEPLOYMENT_BIN")
    @async try
        run(`fprime-gds --root $PROJECT_ROOT --app $DEPLOYMENT_NAME`)
        gds_launched = true
    catch e
        println("❌ Failed to launch GDS with binary: $e")
    end
else
    println("⚠️ Neither deployment YAML nor binary found in $BUILD_DIR")
    println("   Run: fprime-util generate $DEPLOYMENT_NAME && fprime-util build $DEPLOYMENT_NAME")
end

println("🎉 GDS launch task started (may fail silently if missing build)")

# -------------------------
# Start TCP server safely
# -------------------------
server = try
    listen(PORT)
catch e
    println("❌ Failed to bind TCP port $PORT: $e")
    println("   Check for existing process: lsof -i :$PORT")
    exit(1)
end

println("🟢 Julia VESC server listening on port $PORT")

# Accept client
sock = accept(server)
println("🔌 Client connected!")

# -------------------------
# Motor state
# -------------------------
rpm     = 0
duty    = 0.0
current = 0.0
volt    = 24.0
fault   = 0

# -------------------------
# Main loop (20 Hz)
# -------------------------
while true
    try
        # Read command if available
        if bytesavailable(sock) > 0
            cmd = strip(readline(sock))
            println("📥 CMD received: $cmd")

            if startswith(cmd, "duty=")
                duty = try parse(Float64, split(cmd, "=")[2]) catch println("⚠️ Invalid duty"); duty end
            elseif startswith(cmd, "current=")
                current = try parse(Float64, split(cmd, "=")[2]) catch println("⚠️ Invalid current"); current end
            elseif cmd == "stop"
                duty = 0.0
                current = 0.0
            elseif cmd == "fault"
                fault = 1
            elseif cmd == "clear_fault"
                fault = 0
            else
                println("⚠️ Unknown command: $cmd")
            end
        end

        # Simple proportional RPM simulation
        rpm = round(Int, duty * 1000)

        # Send telemetry to client (quiet, no warnings)
        println(sock, @sprintf("rpm=%d duty=%.3f current=%.3f volt=%.1f fault=%d time=%s",
                               rpm, duty, current, volt, fault, Dates.now()))

        sleep(0.05)  # 20 Hz
    catch e
        println("❌ Client disconnected or error: $e")
        close(sock)
        println("🔄 Waiting for client to reconnect...")
        sock = accept(server)
        println("🔌 Client reconnected!")
    end
end
