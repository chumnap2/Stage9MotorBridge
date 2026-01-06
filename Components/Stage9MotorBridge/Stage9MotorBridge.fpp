module Stage9 {

  active component Stage9MotorBridge {

    # -------- Ports --------
    sync input port Ping()

    # -------- Commands --------
    async command SET_DUTY(
      duty: F32  # -0.05 .. +0.05
    )

    async command SET_CURRENT(
      current: F32
    )

    async command STOP()

    # -------- Telemetry --------
    telemetry Duty: F32
    telemetry Current: F32
    telemetry RPM: I32
    telemetry Voltage: F32
    telemetry Fault: I32

  }

}
