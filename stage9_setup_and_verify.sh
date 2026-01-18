cat << 'EOF' > stage9_setup_and_verify.sh
#!/usr/bin/env bash
set -e

echo "=============================="
echo " Stage9 Environment Fix Script"
echo "=============================="

# -------------------------------------------------
# Paths (adjust ONLY if project moves)
# -------------------------------------------------
PROJECT_ROOT="$HOME/fprime-motorbridge/Projects/Stage9MotorBridge"
VENV="$PROJECT_ROOT/fprime-venv"

# -------------------------------------------------
# 1. System prerequisites (ONE TIME)
# -------------------------------------------------
echo "🔧 Checking system prerequisites..."

sudo apt-get update
sudo apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    build-essential \
    libzmq3-dev \
    pkg-config

echo "✅ System packages OK"

# -------------------------------------------------
# 2. Create virtual environment (if missing)
# -------------------------------------------------
cd "$PROJECT_ROOT"

if [ ! -d "$VENV" ]; then
    echo "🐍 Creating Python venv..."
    python3.11 -m venv fprime-venv
else
    echo "🐍 Virtual environment already exists"
fi

# -------------------------------------------------
# 3. Activate venv
# -------------------------------------------------
source "$VENV/bin/activate"
echo "✅ Activated venv: $(which python)"

# -------------------------------------------------
# 4. Upgrade pip tooling
# -------------------------------------------------
pip install --upgrade pip setuptools wheel

# -------------------------------------------------
# 5. Clean broken installs (IMPORTANT)
# -------------------------------------------------
echo "🧹 Cleaning old/broken installs..."
pip uninstall -y fprime-tools pyzmq || true

# -------------------------------------------------
# 6. Install F´ tools WITH GDS (this pulls pyzmq)
# -------------------------------------------------
echo "📦 Installing fprime-tools[gds] == 3.1.0"
pip install "fprime-tools[gds]==3.1.0"

# -------------------------------------------------
# 7. Verify pyzmq (critical failure point before)
# -------------------------------------------------
echo "🔍 Verifying pyzmq..."
python - << 'PYEOF'
import zmq
print("pyzmq OK:", zmq.__version__)
PYEOF

# -------------------------------------------------
# 8. Verify F´ binaries
# -------------------------------------------------
echo "🔍 Verifying F´ binaries..."

echo "fprime-util -> $(which fprime-util || echo MISSING)"
echo "fprime-gds  -> $(which fprime-gds  || echo MISSING)"

if ! command -v fprime-gds >/dev/null 2>&1; then
    echo "❌ fprime-gds NOT FOUND"
    echo "❌ GDS will NOT auto-launch from Julia"
    exit 1
fi

echo "✅ fprime-gds installed correctly"

# -------------------------------------------------
# 9. Final summary
# -------------------------------------------------
echo
echo "=============================="
echo " ✅ Stage9 Environment READY"
echo "=============================="
echo
echo "Next steps:"
echo "  1. source fprime-venv/bin/activate"
echo "  2. julia julia_vesc_server.jl"
echo "  3. python3 motor_client_stage9.py"
echo
EOF
