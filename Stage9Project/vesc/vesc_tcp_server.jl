#!/usr/bin/env julia
# =========================================================
# Stage9 VESC + Telemetry TCP Server (Julia)
# Reuses Stage 8 VESC module
# =========================================================

using Sockets
using Printf
using Base.Threads: @async, sleep

println("🔹 Starting Stage 9 VESC TCP server...")

# -------------------------
# Import Stage 8 VESC module
# -------------------------
try
    include("../../Stage8MotorBridge/MotorBridgeServer.jl")
    # Assume Stage8MotorBridge.MotorBridgeServer exposes `vesc` object
    println("✅ Stage 8 VESC module imported")
catch e
    println("❌ Failed to import Stage 8 VESC module: $e")
    exit(1)
end

println("🔚 Stage 9 VESC TCP server stopped")
