#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Fix git ownership issue (Vercel runs as root)
git config --global --add safe.directory /vercel/path0/flutter || true
git config --global --add safe.directory `pwd`/flutter || true

# Verify Flutter installation
echo "Flutter version:"
flutter --version
echo "Dart version:"
dart --version

# Build Flutter web app
echo "Building Flutter web app..."
cd frontend_flutter
flutter pub get
flutter build web --release

echo "Build completed successfully!"

