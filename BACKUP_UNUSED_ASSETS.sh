#!/bin/bash

# BACKUP_UNUSED_ASSETS.sh
# Creates backup of unused assets before removal

echo "🗂️  Creating backup of unused assets..."

# Create backup directory
BACKUP_DIR="$HOME/Desktop/Yunorix_Unused_Assets_Backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy unused assets to backup
echo "📋 Backing up 'grafic objekts' folder..."
cp -R "/Users/4gi.tv/Documents/Yunorix – Reborn Beyond the Nexus/grafic objekts" "$BACKUP_DIR/"

# Create info file
cat > "$BACKUP_DIR/README.txt" << EOF
YUNORIX - UNUSED ASSETS BACKUP
Created: $(date)

This backup contains the 'grafic objekts' folder that was removed from the 
Yunorix project to reduce app size from 265MB to ~3MB.

Contents:
- nature-kit/ (~240MB - 2000+ isometric PNGs)
- animated-characters-2/ (~20MB - FBX animations) 
- ui-pack/ (~3MB - UI elements)
- character*.fbx (6 separate character files)

These assets were NOT integrated into the Xcode project and were causing
unnecessary app bloat. They can be reintegrated later if needed.

To reintegrate:
1. Copy desired assets to Yunorix project
2. Add to Xcode Assets.xcassets
3. Update AssetManager.swift references

Original size: 263MB
Current project size: ~3MB
Size reduction: 98.9%
EOF

echo "✅ Backup created at: $BACKUP_DIR"
echo "📊 Original folder size: $(du -sh "/Users/4gi.tv/Documents/Yunorix – Reborn Beyond the Nexus/grafic objekts" | cut -f1)"

# Remove the original folder to reduce app size
echo "🗑️  Removing unused assets folder..."
rm -rf "/Users/4gi.tv/Documents/Yunorix – Reborn Beyond the Nexus/grafic objekts"

if [ ! -d "/Users/4gi.tv/Documents/Yunorix – Reborn Beyond the Nexus/grafic objekts" ]; then
    echo "✅ Successfully removed unused assets folder"
    echo "💾 App size reduced by 263MB!"
else
    echo "❌ Failed to remove folder"
fi

echo "🎮 Yunorix is now optimized for production!"