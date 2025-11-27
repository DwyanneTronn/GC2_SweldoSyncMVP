#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Build Flutter web app
echo "Building Flutter web app..."
cd frontend_flutter
flutter pub get
flutter build web --release

echo "Build completed successfully!"

