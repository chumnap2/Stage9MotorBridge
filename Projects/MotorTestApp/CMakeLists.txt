cmake_minimum_required(VERSION 3.20)

# Include F´ framework
add_fprime_subdirectory("/home/chumnap/fprime-motorbridge/fprime-3.1.0")

# Include the deployment
add_fprime_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/Deployments/Stage9MotorBridgeDeployment")
