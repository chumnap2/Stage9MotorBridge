#include "Stage9MotorBridge.hpp"

#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>
#include <cstdio>
#include <algorithm>

namespace Stage9 {

Stage9MotorBridge::Stage9MotorBridge(const char* name)
: Stage9MotorBridgeComponentBase(name), sock(-1)
{
}

void Stage9MotorBridge::init(
  NATIVE_INT_TYPE queueDepth,
  NATIVE_INT_TYPE instance
)
{
  Stage9MotorBridgeComponentBase::init(queueDepth, instance);
  connectSocket();
}

void Stage9MotorBridge::connectSocket()
{
  sock = socket(AF_INET, SOCK_STREAM, 0);

  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_port = htons(12345);
  inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

  if (connect(sock, (sockaddr*)&addr, sizeof(addr)) < 0) {
    perror("Stage9MotorBridge TCP connect failed");
    close(sock);
    sock = -1;
  }
}

void Stage9MotorBridge::run_handler(
  NATIVE_INT_TYPE,
  NATIVE_UINT_TYPE
)
{
  if (sock < 0) return;

  char buf[256];
  int n = recv(sock, buf, sizeof(buf) - 1, MSG_DONTWAIT);
  if (n <= 0) return;

  buf[n] = 0;
  parseTelemetry(buf);
}

void Stage9MotorBridge::parseTelemetry(const char* line)
{
  int rpm = 0, fault = 0;
  float duty = 0.0f, current = 0.0f, volt = 0.0f;

  sscanf(line,
    "rpm=%d duty=%f current=%f volt=%f fault=%d",
    &rpm, &duty, &current, &volt, &fault
  );

  tlmWrite_RPM(rpm);
  tlmWrite_Duty(duty);
  tlmWrite_Current(current);
  tlmWrite_Voltage(volt);
  tlmWrite_Fault(fault);
}

void Stage9MotorBridge::SET_DUTY_cmdHandler(
  FwOpcodeType opCode,
  U32 seq,
  F32 duty
)
{
  duty = std::max(-0.05f, std::min(0.05f, duty));
  sendCmd("duty", duty);
  cmdResponse_out(opCode, seq, Fw::CmdResponse::OK);
}

void Stage9MotorBridge::SET_CURRENT_cmdHandler(
  FwOpcodeType opCode,
  U32 seq,
  F32 current
)
{
  sendCmd("current", current);
  cmdResponse_out(opCode, seq, Fw::CmdResponse::OK);
}

void Stage9MotorBridge::STOP_cmdHandler(
  FwOpcodeType opCode,
  U32 seq
)
{
  sendCmd("stop", 0.0f);
  cmdResponse_out(opCode, seq, Fw::CmdResponse::OK);
}

void Stage9MotorBridge::sendCmd(const char* key, float value)
{
  if (sock < 0) return;

  char line[64];
  snprintf(line, sizeof(line), "%s=%f\n", key, value);
  send(sock, line, strlen(line), 0);
}

}
