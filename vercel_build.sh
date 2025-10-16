#!/bin/bash
set -e

# Download Flutter SDK (version that includes Dart 3.9.0+)
curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.6-stable.tar.xz
tar xf flutter.tar.xz

# Fix git safe directory issue
git config --global --add safe.directory $(pwd)/flutter

# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Disable analytics (optional)
flutter config --no-analytics

# Build Flutter Web (release mode)
flutter config --enable-web
flutter pub get
flutter build web --release
