#!/bin/bash

# 1. Download the stable Flutter SDK
echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 2. Add Flutter to the path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Get dependencies and build
echo "Building the Flutter web app..."
flutter pub get
flutter build web --release