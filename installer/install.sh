
#!/bin/bash

set -euo pipefail

# ENTER INSTALLER
ENTER_OWNER="danielkrvideo-stack"
ENTER_REPOSITORY="Enter"
ENTER_BRANCH="main"

INSTALL_DIR="$HOME/.enter"
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

# Check macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: Enter currently supports macOS only."
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
if ! command -v python3.14 >/dev/null 2>&1 && \
   ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: Python 3 is not installed."
    echo "Install it from https://www.python.org/downloads/"
    exit 1
fi

# Protect existing installation
if [[ -e "$INSTALL_DIR" ]]; then
    echo "ERROR: $INSTALL_DIR already exists."
    echo "Existing files will not be overwritten."
    exit 1
fi

# Protect existing launcher
if [[ -e "$BIN_DIR/Enter" ]]; then
    echo "ERROR: $BIN_DIR/Enter already exists."
    echo "Existing launcher will not be overwritten."
    exit 1
fi

# Download repository temporarily
ARCHIVE_URL="https://github.com/$ENTER_OWNER/$ENTER_REPOSITORY/archive/refs/heads/$ENTER_BRANCH.zip"

echo "Downloading Enter..."
curl -fL --retry 3 "$ARCHIVE_URL" -o "$TEMP_DIR/Enter.zip"

echo "Extracting Enter..."
unzip -q "$TEMP_DIR/Enter.zip" -d "$TEMP_DIR"

SOURCE_DIR="$TEMP_DIR/Enter-$ENTER_BRANCH"

if [[ ! -f "$SOURCE_DIR/enter.py" ]]; then
    echo "ERROR: enter.py was not found."
    exit 1
fi

# Install only runtime files
echo "Installing Enter..."

mkdir -p "$INSTALL_DIR"

cp "$SOURCE_DIR/enter.py" "$INSTALL_DIR/"

if [[ -f "$SOURCE_DIR/config.json" ]]; then
    cp "$SOURCE_DIR/config.json" "$INSTALL_DIR/"
fi

for folder in core commands versions languages; do
    if [[ -d "$SOURCE_DIR/$folder" ]]; then
        cp -R "$SOURCE_DIR/$folder" "$INSTALL_DIR/"
    fi
done

# Create launcher
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/Enter" <<LAUNCHER
#!/bin/sh

if command -v python3.14 >/dev/null 2>&1; then
    exec python3.14 "$INSTALL_DIR/enter.py" "\$@"
elif command -v python3 >/dev/null 2>&1; then
    exec python3 "$INSTALL_DIR/enter.py" "\$@"
else
    echo "ERROR: Python 3 is not installed."
    exit 1
fi
LAUNCHER

chmod +x "$BIN_DIR/Enter"

# Configure PATH
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

case "$SHELL" in
    */zsh)
        SHELL_CONFIG="$HOME/.zprofile"
        ;;
    */bash)
        SHELL_CONFIG="$HOME/.bash_profile"
        ;;
    *)
        SHELL_CONFIG="$HOME/.profile"
        ;;
esac

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
echo "Enter is installed in: $INSTALL_DIR"
echo ""
echo "Restart Terminal or run:"
echo "source \"$SHELL_CONFIG\""
echo ""
echo "Then type: Enter"
echo ""
