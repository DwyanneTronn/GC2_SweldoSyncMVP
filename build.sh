#!/bin/bash
set -e

# Install Flutter (using latest stable that has Dart 3.9.2+)
echo "Installing Flutter..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.38.3-stable.tar.xz -o flutter.tar.xz || \
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
echo "Flutter version:"
flutter --version

# Build Flutter web app
echo "Building Flutter web app..."
cd frontend_flutter
flutter pub get
flutter build web --release

echo "Build completed successfully!"

