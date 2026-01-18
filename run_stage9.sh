cat << 'EOF' > run_stage9.sh
#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
VENV="$PROJECT_ROOT/fprime-venv"

echo "🚀 Stage9 launcher"
echo "📂 Project: $PROJECT_ROOT"

# -------------------------------------------------
# Ensure venv exists
# -------------------------------------------------
if [ ! -d "$VENV" ]; then
    echo "❌ Virtual environment missing"
    echo "👉 Run: ./stage9_setup_and_verify.sh"
    exit 1
fi

# -------------------------------------------------
# Activate venv
# -------------------------------------------------
source "$VENV/bin/activate"

echo "🐍 Python: $(which python)"
echo "🧰 fprime-gds: $(which fprime-gds || echo MISSING)"

if ! command -v fprime-gds >/dev/null 2>&1; then
    echo "❌ fprime-gds not found in venv"
    exit 1
fi

# -------------------------------------------------
# Launch Julia server
# -------------------------------------------------
exec julia julia_vesc_server.jl
EOF
