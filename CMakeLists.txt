cmake_minimum_required(VERSION 3.16)
project(Stage9MotorBridge C CXX)

set(FPRIME_PROJECT_ROOT "$ENV{FPRIME_HOME}")
set(FPRIME_FRAMEWORK_ROOT "$ENV{FPRIME_HOME}")

include(${FPRIME_FRAMEWORK_ROOT}/cmake/FPrime.cmake)

# Do NOT include deployments automatically — restore_build.sh will generate them
message(STATUS "Top-level project loaded. Use restore_build.sh to generate deployment.")
