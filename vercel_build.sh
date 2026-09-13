#!/bin/bash
set -e

echo "=================================================="
echo "      PROPZEN - VERCEL FLUTTER BUILD PIPELINE     "
echo "=================================================="

FLUTTER_CHANNEL="stable"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo ">>> Cloning Flutter SDK ($FLUTTER_CHANNEL branch)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b $FLUTTER_CHANNEL "$FLUTTER_DIR"
else
  echo ">>> Flutter SDK found in cache: $FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"

echo ">>> Disabling Flutter analytics & telemetry..."
flutter config --no-analytics

echo ">>> Verifying Flutter installation..."
flutter --version

echo ">>> Fetching package dependencies..."
flutter pub get

echo ">>> Compiling Web Production Release Bundle..."
flutter build web --release --base-href /

echo "=================================================="
echo "    FLUTTER WEB BUILD COMPLETE: build/web ready   "
echo "=================================================="
