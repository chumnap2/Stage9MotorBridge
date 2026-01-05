#!/bin/bash
# =====================================================
# Stage9MotorBridge Safe Restore + Build + GDS
# =====================================================

BASE_DIR=~/fprime-motorbridge
PROJECT_ROOT="$BASE_DIR/Projects/Stage9Project"
DEPLOY_DIR="$PROJECT_ROOT/Deployments/Stage9MotorBridgeDeployment"
DEPLOY_FPP="$DEPLOY_DIR/Stage9MotorBridgeDeployment.fpp"
TOPO_DIR="$PROJECT_ROOT/Topologies"
TOPO_FILE="$TOPO_DIR/Stage9MotorBridgeTopology.fpp"
VENV_DIR="$BASE_DIR/fprime-venv-310"
FRAMEWORK_DIR="$BASE_DIR/fprime-3.1.0"

echo "🚀 Starting Stage9MotorBridge safe restore..."

# -------------------------
# Activate virtualenv
# -------------------------
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
    echo "🟢 Virtualenv activated"
else
    echo "⚠️ Virtualenv not found — continuing anyway"
fi

# -------------------------
# Ensure generic toolchain exists
# -------------------------
cd "$FRAMEWORK_DIR/cmake/toolchain" || echo "⚠️ Could not cd to toolchain dir"
if [ ! -f generic.cmake ]; then
    cp toolchain.cmake.template generic.cmake 2>/dev/null && echo "✅ generic.cmake created"
else
    echo "✅ generic.cmake already exists"
fi

# -------------------------
# Fix Deployment FPP
# -------------------------
mkdir -p "$DEPLOY_DIR"
cat > "$DEPLOY_FPP" <<EOF
deployment Stage9MotorBridgeDeployment {
    platform = "generic"
    topology = Stage9MotorBridgeTopology
}
EOF
echo "✅ Deployment FPP fixed (platform = generic)"

# -------------------------
# Ensure Topology exists
# -------------------------
if [ ! -f "$TOPO_FILE" ]; then
    mkdir -p "$TOPO_DIR"
    cat > "$TOPO_FILE" <<EOF
topology Stage9MotorBridgeTopology {
    // Add Stage9MotorBridge component instance here
}
EOF
    echo "✅ Placeholder topology created"
else
    echo "✅ Topology FPP exists"
fi

# -------------------------
# Clean old build caches
# -------------------------
cd "$PROJECT_ROOT"
rm -rf build* .fprime-cache ~/build-fprime-automatic-* 2>/dev/null
echo "🧹 Build caches removed"

# -------------------------
# Generate deployment (errors won't exit)
# -------------------------
echo "⚙️ Generating deployment..."
fprime-util generate "$DEPLOY_DIR" --platform generic || echo "⚠️ Deployment generation FAILED, check FPP/toolchain"

# -------------------------
# Build deployment (errors won't exit)
# -------------------------
echo "🏗️ Building deployment..."
fprime-util build "$DEPLOY_DIR" || echo "⚠️ Deployment build FAILED, check build cache"

# -------------------------
# Launch GDS (errors won't exit)
# -------------------------
echo "🎮 Launching GDS..."
fprime-gds --app "$DEPLOY_DIR" || echo "⚠️ GDS launch failed — app binary may not exist yet"

echo "✅ Stage9MotorBridge safe restore script finished (no terminal exit)"
