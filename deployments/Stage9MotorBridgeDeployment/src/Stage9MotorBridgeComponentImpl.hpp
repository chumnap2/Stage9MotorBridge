#pragma once
#include <Fw/Types/BasicTypes.hpp>
#include <FpConfig.hpp>

namespace Stage9MotorBridge {

class Stage9MotorBridgeComponentImpl {
public:
    void PING_cmdHandler(const FwOpcodeType opCode, const U32 cmdSeq);
};

} // namespace Stage9MotorBridge
