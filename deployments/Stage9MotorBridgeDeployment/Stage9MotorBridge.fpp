component Stage9MotorBridge {
    ports {
        # Telemetry from VESC to GDS
        output motorTelemetry: U32;

        # Commands to VESC from GDS
        input setDuty: U32;
        input setCurrent: I32;
        input setRPM: I32;
    }
}
