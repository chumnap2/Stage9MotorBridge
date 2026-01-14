#!/usr/bin/env bash
set -euo pipefail

source ./env.sh

echo "=== Cleaning old build directories ==="
fprime-util purge Stage9MotorBridgeDeployment || true
rm -rf "$PROJECT_ROOT"/build-fprime-automatic-*

echo "=== Restoring deployment CMakeLists.txt from template ==="
cp Deployments/Stage9MotorBridgeDeployment/CMakeLists.txt.template    Deployments/Stage9MotorBridgeDeployment/CMakeLists.txt

echo "=== Generating F´ deployment build ==="
fprime-util generate Stage9MotorBridgeDeployment
fprime-util build Stage9MotorBridgeDeployment

echo "=== Restore and build completed successfully ==="
