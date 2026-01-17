cmake_minimum_required(VERSION 3.13)
project(Stage9MotorBridgeDeployment)

# F´ 3.1.0 expects both roots to point to the framework for deployments
set(FPRIME_PROJECT_ROOT "$ENV{FPRIME_HOME}")
set(FPRIME_FRAMEWORK_ROOT "$ENV{FPRIME_HOME}")

include(${FPRIME_FRAMEWORK_ROOT}/cmake/FPrime.cmake)

add_fprime_deployment(
  "${CMAKE_CURRENT_LIST_DIR}"
  "${PROJECT_NAME}"
)
