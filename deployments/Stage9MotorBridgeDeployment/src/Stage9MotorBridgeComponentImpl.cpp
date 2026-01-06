#include "Stage9MotorBridgeComponentImpl.hpp"

namespace Stage9MotorBridge {

void Stage9MotorBridgeComponentImpl::PING_cmdHandler(
    const FwOpcodeType opCode,
    const U32 cmdSeq
) {
    this->log_ACTIVITY_LOW_PingReceived();
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}

} // namespace Stage9MotorBridge
