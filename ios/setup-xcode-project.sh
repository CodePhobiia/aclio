#!/bin/bash

# Aclio iOS Project Setup Script
# This script generates the Xcode project using XcodeGen

set -e

echo "🐰 Aclio iOS Project Setup"
echo "=========================="

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen..."
    brew install xcodegen
else
    echo "✅ XcodeGen is already installed"
fi

# Navigate to the Aclio directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/Aclio"

echo "📁 Working directory: $(pwd)"

# Generate the Xcode project
echo "🔨 Generating Xcode project..."
xcodegen generate

# Check if project was created
if [ -d "Aclio.xcodeproj" ]; then
    echo "✅ Xcode project created successfully!"
    
    # Move project to parent ios/ directory
    mv Aclio.xcodeproj ../
    
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Open the project:  open ../Aclio.xcodeproj"
    echo "  2. Select your Team in Signing & Capabilities"
    echo "  3. Add RevenueCat: File → Add Package Dependencies"
    echo "     URL: https://github.com/RevenueCat/purchases-ios.git"
    echo "  4. Build and run! (⌘R)"
    echo ""
    
    # Ask if user wants to open the project
    read -p "Open Xcode project now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open ../Aclio.xcodeproj
    fi
else
    echo "❌ Failed to create Xcode project"
    exit 1
fi

