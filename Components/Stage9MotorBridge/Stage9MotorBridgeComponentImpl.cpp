#include "Components/Stage9MotorBridge/Stage9MotorBridgeComponentImpl.hpp"

Stage9MotorBridgeComponentImpl::Stage9MotorBridgeComponentImpl(
  const char* compName
) : Stage9MotorBridgeComponentBase(compName)
{
}

void Stage9MotorBridgeComponentImpl::PING_cmdHandler(
  const FwOpcodeType opCode,
  const U32 cmdSeq
)
{
  this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}
