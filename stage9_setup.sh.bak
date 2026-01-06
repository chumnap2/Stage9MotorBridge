#!/usr/bin/env julia
# =========================================================
# Stage9MotorBridge – Julia VESC TCP Server (Robust)
# =========================================================

using Sockets
using Printf
using Logging

# -------------------------
# Configuration
# -------------------------
HOST = ip"127.0.0.1"   # IP literal instead of String
PORT = 12345

PROJECT_ROOT = "/home/chumnap/fprime-motorbridge/Projects/Stage9Project"
DEPLOYMENT_NAME = "Stage9MotorBridgeDeployment"
BUILD_DIR = joinpath(PROJECT_ROOT, "build-fprime-automatic-$DEPLOYMENT_NAME")

# -------------------------
# Build directory check
# -------------------------
if !isdir(BUILD_DIR)
    error("❌ Build directory missing: $BUILD_DIR. Run fprime-util generate + build first.")
end
println("✅ Build directory found: $BUILD_DIR")

# -------------------------
# Locate _GDS.yaml safely
# -------------------------
all_files = readdir(BUILD_DIR, join=true)
yaml_candidates = filter(f -> occursin("_GDS.yaml", f), all_files)
GDS_YAML = length(yaml_candidates) > 0 ? yaml_candidates[1] : nothing

if GDS_YAML === nothing
    @warn "No _GDS.yaml found. It will be generated dynamically when GDS launches."
end
println("ℹ️ Using GDS YAML: ", GDS_YAML === nothing ? "dynamic generation" : GDS_YAML)

# -------------------------
# Helper: safe float parsing
# -------------------------
function safe_parse_float(str::AbstractString)
    try
        return parse(Float64, str)
    catch e
        @warn "Failed to parse '$str' as Float64: $e"
        return 0.0
    end
end

# -------------------------
# TCP Server (multi-client, reconnect-safe)
# -------------------------
println("🚀 Starting VESC TCP server on $HOST:$PORT...")

server = listen(HOST, PORT)  # ✅ Use IP literal

function handle_client(client::TCPSocket)
    println("✅ Client connected: ", client)
    try
        while !eof(client)
            line = strip(readline(client))
            isempty(line) && continue

            # Safe command parsing
            parts = split(line; limit=2)
            cmd = parts[1]
            val_num = length(parts) == 2 ? safe_parse_float(parts[2]) : 0.0

            println(@sprintf("Received command '%s' with value %.3f", cmd, val_num))
            
            # TODO: implement actual VESC command here
            write(client, "ACK $cmd\n")
        end
    catch e
        @warn "Client error: $e"
    finally
        println("ℹ️ Client disconnected: ", client)
        close(client)
    end
end

# -------------------------
# Accept clients asynchronously
# -------------------------
@async begin
    try
        while true
            client = accept(server)
            @async handle_client(client)
        end
    catch e
        @warn "Server error: $e"
    finally
        close(server)
    end
end

println("✅ VESC TCP server running (Ctrl+C to stop)")

# -------------------------
# Keep server alive
# -------------------------
while true
    sleep(1)
end
