cmake_minimum_required(VERSION 3.13)
project(Stage9Project)

set(FPRIME_FRAMEWORK_PATH "/home/chumnap/fprime-motorbridge/fprime-3.1.0")
include(${FPRIME_FRAMEWORK_PATH}/cmake/FPrime.cmake)

# Only deployments define build roots in F´ v3.x
add_fprime_subdirectory("/home/chumnap/fprime-motorbridge/Projects/Stage9Project/Deployments/Stage9MotorBridgeDeployment")
