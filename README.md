# Stage9MotorBridge

This repository contains:

- Stage9Project: Julia TCP server for VESC control
- F´ deployment: Stage9MotorBridgeDeployment
- Scripts to launch and test the Stage9 TCP server

## Usage

1. Make sure F' v3.1.0 framework is installed at `/home/chumnap/fprime-motorbridge/fprime-3.1.0`
2. Run build:
   ```
   fprime-util generate
   fprime-util build
   ```
3. Launch TCP server:
   ```
   julia stage9_setup.jl
   ```

