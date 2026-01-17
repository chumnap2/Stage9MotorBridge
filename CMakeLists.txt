cmake_minimum_required(VERSION 3.16)
project(Stage9MotorBridge C CXX)

# Project root
set(FPRIME_PROJECT_ROOT ${CMAKE_CURRENT_LIST_DIR})

# F´ framework location (exported by env.sh)
set(FPRIME_FRAMEWORK_ROOT "$ENV{FPRIME_HOME}")

include(${FPRIME_FRAMEWORK_ROOT}/cmake/FPrime.cmake)

# Only include deployments when they exist (generated)
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/Deployments/Stage9MotorBridgeDeployment/CMakeLists.txt")
  add_fprime_subdirectory(
    ${CMAKE_CURRENT_LIST_DIR}/Deployments/Stage9MotorBridgeDeployment
  )
endif()
