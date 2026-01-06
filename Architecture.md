Stage 9 Motor Bridge — Architecture
==================================

VESC (USB/Serial)
   ⇅
Julia TCP Server  (127.0.0.1:12345)
   ⇅   JSON / line protocol
Stage9MotorBridge (F´ component)
   ⇅
F´ GDS (telemetry + commands)

Layer Responsibilities
----------------------

Stage9MotorBridge:
- Opens TCP client socket
- Reads telemetry lines
- Sends command lines
- Exposes data via F´ telemetry
- Accepts commands via F´ GDS

Safety:
- Duty clamp ±0.05
- STOP command
- Non-blocking socket
- No startup motion
