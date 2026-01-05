#!/usr/bin/env bash
# =========================================================
# Stage9MotorBridge – F´ v3.1.0 Prescan/Build/GDS Correct Setup
# Component CMakeLists empty, top-level handles prescan
# =========================================================

set -euo pipefail
IFS=$'\n\t'

# -------------------------
# Paths
# -------------------------
BASE_DIR="$HOME/fprime-motorbridge"
PROJECT_ROOT="$BASE_DIR/Projects/Stage9Project"
FRAMEWORK_DIR="$BASE_DIR/fprime-3.1.0"
VENV_DIR="$BASE_DIR/fprime-venv-310"

COMPONENT_DIR="$PROJECT_ROOT/Components/Dummy"
TOPOLOGY_DIR="$PROJECT_ROOT/Topologies"
DEPLOYMENT_DIR="$PROJECT_ROOT/Deployments/Stage9MotorBridgeDeployment"

mkdir -p "$COMPONENT_DIR" "$TOPOLOGY_DIR" "$DEPLOYMENT_DIR"

# -------------------------
# Activate virtualenv
# -------------------------
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "❌ Virtualenv not found at $VENV_DIR"
    exit 1
fi
source "$VENV_DIR/bin/activate"
echo "🟢 Virtualenv active"

# -------------------------
# Clean previous builds
# -------------------------
rm -rf "$PROJECT_ROOT"/build* "$PROJECT_ROOT"/.fprime-cache || true
echo "🧹 Clean slate"

# -------------------------
# Project-level settings.ini
# -------------------------
cat > "$PROJECT_ROOT/settings.ini" <<EOF
[fprime]
framework_path = $FRAMEWORK_DIR
platform = linux
project_root = $PROJECT_ROOT
EOF
echo "✅ settings.ini created"

# -------------------------
# Dummy Component
# -------------------------
cat > "$COMPONENT_DIR/Dummy.fpp" <<EOF
module DummyModule {
  passive component Dummy {
    sync input port Ping()
  }
}
EOF

# Component CMakeLists.txt must be empty or contain only a comment
cat > "$COMPONENT_DIR/CMakeLists.txt" <<EOF
# Prescan-safe: handled by top-level CMakeLists
EOF
echo "✅ Dummy component defined (CMakeLists empty)"

# -------------------------
# Topology
# -------------------------
cat > "$TOPOLOGY_DIR/Stage9MotorBridgeTopology.fpp" <<EOF
module Stage9 {
  topology Stage9MotorBridgeTopology {
    instance dummy: DummyModule::Dummy base id 0x100
  }
}
EOF

# Topology CMakeLists.txt empty for prescan
cat > "$TOPOLOGY_DIR/CMakeLists.txt" <<EOF
# Prescan-safe: handled by top-level CMakeLists
EOF
echo "✅ Topology defined"

# -------------------------
# Deployment
# -------------------------
cat > "$DEPLOYMENT_DIR/Stage9MotorBridgeDeployment.fpp" <<EOF
deployment Stage9MotorBridgeDeployment {
  platform = "linux"
  topology = Stage9::Stage9MotorBridgeTopology
}
EOF

# Deployment CMakeLists empty for prescan
cat > "$DEPLOYMENT_DIR/CMakeLists.txt" <<EOF
# Prescan-safe: handled by top-level CMakeLists
EOF
echo "✅ Deployment defined"

# -------------------------
# Top-level CMakeLists.txt (CRITICAL)
# -------------------------
cat > "$PROJECT_ROOT/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.13)
project(Stage9Project)

set(FPRIME_FRAMEWORK_PATH "$FRAMEWORK_DIR")
include(\${FPRIME_FRAMEWORK_PATH}/cmake/FPrime.cmake)

# Add components/deployments for prescan
add_fprime_subdirectory("$COMPONENT_DIR")
add_fprime_subdirectory("$DEPLOYMENT_DIR")
EOF
echo "✅ Top-level CMakeLists written (prescan-safe)"

# -------------------------
# Generate + Build Deployment
# -------------------------
cd "$PROJECT_ROOT"

fprime-util generate Stage9MotorBridgeDeployment
echo "✅ Deployment generation succeeded"

fprime-util build Stage9MotorBridgeDeployment
echo "✅ Deployment build succeeded"

# -------------------------
# Launch GDS
# -------------------------
GDS_YAML="$PROJECT_ROOT/build-fprime-automatic-Stage9MotorBridgeDeployment/Stage9MotorBridgeDeployment_GDS.yaml"

if [ ! -f "$GDS_YAML" ]; then
    echo "❌ Deployment GDS YAML not found at $GDS_YAML"
    exit 1
fi

fprime-gds --app "$GDS_YAML"
echo "🎉 Stage9MotorBridge setup complete!"
