#!/bin/bash
set -e

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing Flutter..."
    
    # Clone Flutter repository
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    
    # Add Flutter to PATH
    export PATH="$PATH:$(pwd)/flutter/bin"
    
    # Run Flutter doctor
    flutter doctor
    
    # Enable Flutter web
    flutter config --enable-web
fi

# Ensure Flutter is in PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build Flutter web app
echo "Building Flutter web app..."
flutter build web --release --base-href /

echo "Build complete!"
