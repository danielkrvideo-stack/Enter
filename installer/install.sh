
#!/bin/bash

set -euo pipefail

# ENTER INSTALLER
ENTER_NAME="Enter"
ENTER_OWNER="danielkrvideo-stack"
ENTER_REPOSITORY="Enter"
ENTER_BRANCH="main"

INSTALL_DIR="$HOME/Enter-Test"
BIN_DIR="$HOME/.local/bin"

TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

echo ""
echo "================================"
echo "       ENTER INSTALLER"
echo "================================"
echo ""

# Check operating system
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: This installer currently supports macOS only."
    exit 1
fi

# Check required tools
for tool in curl unzip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool not found: $tool"
        exit 1
    fi
done

# Check Python
if command -v python3.14 >/dev/null 2>&1; then
    PYTHON_COMMAND="python3.14"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_COMMAND="python3"
else
    echo "ERROR: Python 3 is not installed."
    echo "Install Python from https://www.python.org/downloads/"
    exit 1
fi

echo "Python found: $PYTHON_COMMAND"

# Prevent accidental overwrite
if [[ -e "$INSTALL_DIR" ]]; then
    echo ""
    echo "ERROR: $INSTALL_DIR already exists."
    echo "The installer will not overwrite existing files."
    echo "Move or rename the existing folder before installing."
    exit 1
fi

# Download Enter
ARCHIVE_URL="https://github.com/$ENTER_OWNER/$ENTER_REPOSITORY/archive/refs/heads/$ENTER_BRANCH.zip"

echo ""
echo "Downloading Enter..."

curl -fL --retry 3 \
    "$ARCHIVE_URL" \
    -o "$TEMP_DIR/Enter.zip"

echo "Extracting files..."

unzip -q "$TEMP_DIR/Enter.zip" -d "$TEMP_DIR"

SOURCE_DIR="$TEMP_DIR/Enter-$ENTER_BRANCH"

# Check downloaded project
if [[ ! -f "$SOURCE_DIR/enter.py" ]]; then
    echo ""
    echo "ERROR: enter.py was not found."
    echo "The Enter repository is not ready for installation yet."
    exit 1
fi

# Install Enter
echo "Installing Enter..."

mkdir -p "$INSTALL_DIR"
cp -R "$SOURCE_DIR/." "$INSTALL_DIR/"

# Create launcher
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/Enter" <<'LAUNCHER'
#!/bin/sh

if command -v python3.14 >/dev/null 2>&1; then
    exec python3.14 "$HOME/Enter/enter.py" "$@"
elif command -v python3 >/dev/null 2>&1; then
    exec python3 "$HOME/Enter/enter.py" "$@"
else
    echo "ERROR: Python 3 is not installed."
    exit 1
fi
LAUNCHER

chmod +x "$BIN_DIR/Enter"

# Add launcher directory to PATH
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

if [[ "$SHELL" == */zsh ]]; then
    SHELL_CONFIG="$HOME/.zprofile"
else
    SHELL_CONFIG="$HOME/.bash_profile"
fi

touch "$SHELL_CONFIG"

if ! grep -Fq "$PATH_LINE" "$SHELL_CONFIG"; then
    echo "" >> "$SHELL_CONFIG"
    echo "$PATH_LINE" >> "$SHELL_CONFIG"
fi

echo ""
echo "================================"
echo "       ENTER INSTALLED!"
echo "================================"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo "Launcher: $BIN_DIR/Enter"
echo ""
echo "Restart Terminal or run:"
echo "source $SHELL_CONFIG"
echo ""
echo "Then type: Enter"
echo ""
