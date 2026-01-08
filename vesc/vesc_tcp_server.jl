#!/usr/bin/env julia
# =========================================================
# Stage 9 VESC TCP Server (Standalone, Clean)
# =========================================================

using Sockets
using PyCall
using Printf
using Base.Threads: @async, sleep

println("🔹 Starting Stage 9 VESC TCP server...")

# -------------------------
# Ensure local Python files are visible
# -------------------------
pushfirst!(PyVector(pyimport("sys")."path"), @__DIR__)

# -------------------------
# Sanity-check Python dependencies
# -------------------------
try
    pyimport("serial")
    println("✅ Python dependency 'pyserial' found")
catch e
    println("❌ Missing Python dependency: pyserial")
    println("➡️ Fix with:")
    println("   source ~/fprime-motorbridge/fprime-venv-310/bin/activate")
    println("   pip install pyserial")
    exit(1)
end

# -------------------------
# Import VESC module
# -------------------------
try
    vesc_mod = pyimport("vescminimal_nov20")
    vesc = vesc_mod.VESC("/dev/ttyACM0")
    println("✅ VESC initialized on /dev/ttyACM0")
catch e
    println("❌ Failed to initialize VESC module:")
    println(e)
    exit(1)
end

# -------------------------
# TCP configuration
# -------------------------
HOST = ip"127.0.0.1"
PORT = 12345

last_duty = 0.0
running = true

clamp_val(x, lo, hi) = max(lo, min(hi, x))

# -------------------------
# Background duty sender
# -------------------------
@async begin
    while running
        try
            vesc.set_duty_cycle(last_duty)
        catch e
            println("❌ Duty send error: $e")
        end
        sleep(0.05)
    end
end

# -------------------------
# TCP server
# -------------------------
server = listen(HOST, PORT)
println("✅ Listening on $HOST:$PORT")

while running
    sock = accept(server)
    println("🔗 Client connected")

    try
        while !eof(sock)
            cmd = strip(readline(sock))
            isempty(cmd) && continue

            println("📥 $cmd")

            if cmd == "stop"
                last_duty = 0.0
                println("🛑 Duty set to 0")

            elseif startswith(cmd, "duty")
                val = parse(Float64, split(cmd)[2])
                last_duty = clamp_val(val, -1.0, 1.0)
                println("➡️ Duty = $last_duty")

            elseif cmd == "telemetry"
                rpm = vesc.get_rpm()
                current = vesc.get_current()
                voltage = vesc.get_input_voltage()
                write(sock,
                    @sprintf(
                        "RPM: %.1f I: %.2fA V: %.2fV\n",
                        rpm, current, voltage
                    )
                )

            elseif cmd == "exit"
                running = false
                break

            else
                println("⚠️ Unknown command")
            end
        end
    catch e
        println("⚠️ Client error: $e")
    end

    close(sock)
    println("🔌 Client disconnected")
end

println("🔚 Stage 9 VESC TCP server stopped")
