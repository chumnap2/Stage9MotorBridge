#include "Stage9MotorBridgeComponentImpl.hpp"
#include <Fw/Types/BasicTypes.hpp>

namespace Stage9MotorBridge {

void Stage9MotorBridgeComponentImpl::PING_cmdHandler(
    const FwOpcodeType opCode,
    const U32 cmdSeq
) {
    // No-op command: confirms command path works
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}

} // namespace Stage9MotorBridge
