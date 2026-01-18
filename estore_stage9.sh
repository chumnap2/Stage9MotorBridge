#!/usr/bin/env bash
set -e
echo "🔹 Stage 9 Restore Script: Full venv + build + GDS + Julia Server"

# --------------------------
# Install essential build tools and headers
# --------------------------
echo "📦 Installing system packages..."
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake git pkg-config curl \
    libzmq3-dev

# --------------------------
# Install pyenv for Python 3.11
# --------------------------
if [ ! -d "$HOME/.pyenv" ]; then
    echo "🐍 Installing pyenv..."
    curl https://pyenv.run | bash
fi

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# --------------------------
# Install Python 3.11.8 and virtualenv
# --------------------------
if ! pyenv versions | grep -q "3.11.8"; then
    echo "🐍 Installing Python 3.11.8 via pyenv..."
    pyenv install 3.11.8
fi

if ! pyenv virtualenvs | grep -q "fprime311"; then
    echo "🐍 Creating virtualenv fprime311..."
    pyenv virtualenv 3.11.8 fprime311
fi

echo "🔹 Activating virtualenv..."
pyenv activate fprime311

# --------------------------
# Upgrade pip/wheel and install Python deps
# --------------------------
echo "📦 Upgrading pip, setuptools, wheel..."
pip install --upgrade pip setuptools wheel

echo "📦 Installing pyzmq, pyserial, pyvesc..."
pip install "pyzmq>=23.2,<26" --prefer-binary
pip install pyserial
pip install pyvesc

# --------------------------
# Paths for F' Stage 9
# --------------------------
FPRIME_HOME="$HOME/fprime-motorbridge/fprime-3.1.0"
PROJECT_ROOT="$HOME/fprime-motorbridge/Projects/Stage9MotorBridge"

cd "$PROJECT_ROOT"

# --------------------------
# Purge old builds
# --------------------------
echo "🗑️ Purging old F' builds..."
fprime-util purge --yes

# --------------------------
# Generate & build deployment
# --------------------------
echo "⚙️ Generating F' deployment..."
fprime-util generate

echo "⚙️ Building F' deployment..."
fprime-util build

# --------------------------
# Ready to launch
# --------------------------
echo "✅ Stage 9 restore complete!"
echo "💡 Next steps:"
echo "1️⃣ Activate virtualenv: pyenv activate fprime311"
echo "2️⃣ Launch Julia VESC server: julia julia_vesc_server.jl"
echo "3️⃣ In another terminal (same venv), run client: python3 motor_client_stage9.py"
echo "4️⃣ Launch F' GDS: fprime-gds"

