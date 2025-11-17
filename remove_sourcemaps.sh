#!/bin/bash

# Script to remove sourcemap references from Flutter web build files
# This prevents console errors about missing source map files in production

BUILD_DIR="build/web"

if [ ! -d "$BUILD_DIR" ]; then
  echo "Error: Build directory $BUILD_DIR not found"
  exit 1
fi

echo "Removing sourcemap references from Flutter web build..."

# Remove sourcemap reference from flutter_bootstrap.js
if [ -f "$BUILD_DIR/flutter_bootstrap.js" ]; then
  sed -i 's|//# sourceMappingURL=.*||g' "$BUILD_DIR/flutter_bootstrap.js"
  echo "✓ Removed sourcemap reference from flutter_bootstrap.js"
fi

# Remove sourcemap reference from flutter.js (if it exists)
if [ -f "$BUILD_DIR/flutter.js" ]; then
  sed -i 's|//# sourceMappingURL=.*||g' "$BUILD_DIR/flutter.js"
  echo "✓ Removed sourcemap reference from flutter.js"
fi

# Remove sourcemap reference from main.dart.js
if [ -f "$BUILD_DIR/main.dart.js" ]; then
  sed -i 's|//# sourceMappingURL=.*||g' "$BUILD_DIR/main.dart.js"
  echo "✓ Removed sourcemap reference from main.dart.js"
fi

echo "Done! Sourcemap references removed."
