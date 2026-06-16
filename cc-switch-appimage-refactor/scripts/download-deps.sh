#!/bin/bash
set -euo pipefail

DEST_DIR="/home/reallab_zwx/Desktop/cc-switch-appimage-refactor/vendored-deps/debs"
BASE_URL="http://archive.ubuntu.com/ubuntu/pool"
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

download() {
  local url="$1"
  local fname="$(basename "$url")"
  if [ -f "$fname" ]; then
    echo "  (skip) $fname"
  else
    echo "  -> $fname"
    wget -q --show-progress "$url" 2>&1 || echo "    FAILED: $url"
  fi
}

echo "=== Downloading webkit2gtk-4.1 pkgs ==="
# Try jammy security update first, then original jammy release
WEBKIT_BASE="$BASE_URL/main/w/webkit2gtk"
for ver in "2.50.4-0ubuntu0.22.04.1" "2.36.0-2ubuntu1"; do
  for pkg in \
    "libwebkit2gtk-4.1-0_${ver}_amd64.deb" \
    "libwebkit2gtk-4.1-dev_${ver}_amd64.deb" \
    "libjavascriptcoregtk-4.1-0_${ver}_amd64.deb" \
    "libjavascriptcoregtk-4.1-dev_${ver}_amd64.deb" \
    "gir1.2-webkit2-4.1_${ver}_amd64.deb" \
    "gir1.2-javascriptcoregtk-4.1_${ver}_amd64.deb"; do
    download "$WEBKIT_BASE/$pkg"
  done
done

echo ""
echo "=== Downloading libsoup-3.0 pkgs ==="
SOUP_URL="$BASE_URL/main/libs/libsoup3/"
# Try jammy build2 first, then security update
for tries in \
  "libsoup-3.0-0_3.4.4-5build2_amd64.deb" \
  "libsoup-3.0-dev_3.4.4-5build2_amd64.deb" \
  "libsoup-3.0-common_3.4.4-5build2_all.deb" \
  "gir1.2-soup-3.0_3.4.4-5build2_amd64.deb" \
  "libsoup-3.0-0_3.4.4-5ubuntu0.7_amd64.deb" \
  "libsoup-3.0-common_3.4.4-5ubuntu0.7_all.deb"; do
  download "$SOUP_URL$tries"
done

echo ""
echo "=== Downloading glib2.0 pkgs from jammy ==="
GLIB_URL="$BASE_URL/main/g/glib2.0/"
for ver in "2.72.4-0ubuntu2.9" "2.72.1-1"; do
  for pkg in \
    "libglib2.0-0_${ver}_amd64.deb" \
    "libglib2.0-dev_${ver}_amd64.deb" \
    "libglib2.0-data_${ver}_all.deb" \
    "libglib2.0-bin_${ver}_amd64.deb" \
    "libglib2.0-dev-bin_${ver}_amd64.deb"; do
    download "$GLIB_URL$pkg"
  done
done

echo ""
echo "=== Also need libsoup-3.0-dev ==="
# libsoup-3.0-dev for jammy - try to find it
download "$SOUP_URL""libsoup-3.0-dev_3.4.4-5build2_amd64.deb" 2>/dev/null || true

echo ""
echo "=== Also download libgio-2.0-dev (newer) ==="
for ver in "2.72.4-0ubuntu2.9" "2.72.1-1"; do
  download "$GLIB_URL""libgio-2.0-dev_${ver}_amd64.deb" 2>/dev/null || true
  download "$GLIB_URL""libgio-2.0-dev-bin_${ver}_amd64.deb" 2>/dev/null || true
done

echo ""
echo "=== Files downloaded: ==="
ls -lh "$DEST_DIR/"
