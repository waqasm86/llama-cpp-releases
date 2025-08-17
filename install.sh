#!/bin/sh -eu
# llama.cpp one-liner installer for Linux (CPU+CUDA)
ARCH="$(uname -m)"
OS="$(uname -s)"
[ "$OS" = "Linux" ] || { echo "Linux only"; exit 1; }

# 'latest' (default) will use the Releases 'latest' endpoint.
# Set VER=v0.1.0 to pin to a specific tag.
VER="${VER:-latest}"

if [ "$VER" = "latest" ]; then
  BASE="https://github.com/waqasm86/llama-cpp-releases/releases/latest/download"
else
  BASE="https://github.com/waqasm86/llama-cpp-releases/releases/download/$VER"
fi

TARBALL="llama.cpp-${ARCH}.tar.xz"
URL="${BASE}/${TARBALL}"

PREFIX="/opt/llama.cpp"
BIN1="/usr/local/bin/llama-cli"
BIN2="/usr/local/bin/llama-server"

have() { command -v "$1" >/dev/null 2>&1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
DOWNLOADER=""
if have curl; then DOWNLOADER="curl -fsSL"; elif have wget; then DOWNLOADER="wget -qO-"; else
  echo "Need curl or wget"; exit 1
fi

# Download tarball (+ optional checksum)
if [ "$DOWNLOADER" = "curl -fsSL" ]; then
  curl -fsSL "$URL" -o "$TMP/p.txz"
  curl -fsSL "${URL}.sha256" -o "$TMP/p.sha256" || true
else
  wget -qO "$TMP/p.txz" "$URL"
  wget -qO "$TMP/p.sha256" "${URL}.sha256" || true
fi

if [ -s "$TMP/p.sha256" ] && command -v sha256sum >/dev/null 2>&1; then
  (cd "$TMP" && sha256sum -c p.sha256)
fi

# Install to /opt + symlinks
SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"
$SUDO mkdir -p "$PREFIX"
$SUDO tar -C "$PREFIX" -xJf "$TMP/p.txz"
$SUDO ln -sf "$PREFIX/bin/llama-cli"    "$BIN1"
$SUDO ln -sf "$PREFIX/bin/llama-server" "$BIN2"

echo "Installed to $PREFIX"
echo "Use:  llama-cli   -m /path/model.gguf -p 'hello'"
echo "Or :  USE_CUDA=yes llama-server -m /path/model.gguf --host 0.0.0.0 --port 8080"
