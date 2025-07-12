# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Yunorix – Reborn Beyond the Nexus" is a cross-platform 3D game built with SceneKit, targeting both iOS and macOS. The project uses a shared codebase architecture with platform-specific view controllers.

## Build Commands

### Building the Project
```bash
# Build iOS target
xcodebuild -project "Yunorix – Reborn Beyond the Nexus.xcodeproj" -scheme "Yunorix – Reborn Beyond the Nexus iOS" -configuration Debug

# Build macOS target  
xcodebuild -project "Yunorix – Reborn Beyond the Nexus.xcodeproj" -scheme "Yunorix – Reborn Beyond the Nexus macOS" -configuration Debug

# Clean build
xcodebuild clean -project "Yunorix – Reborn Beyond the Nexus.xcodeproj"
```

### Running the Project
Open `Yunorix – Reborn Beyond the Nexus.xcodeproj` in Xcode and use Cmd+R to run on the desired platform.

## Architecture

### Core Structure
- **Shared Module** (`Yunorix – Reborn Beyond the Nexus Shared/`): Contains cross-platform game logic
  - `GameController.swift`: Main game controller implementing `SCNSceneRendererDelegate`
  - `Art.scnassets/`: 3D assets including `ship.scn` and textures
  - `Assets.xcassets/`: App icons and color assets

- **iOS Module** (`Yunorix – Reborn Beyond the Nexus iOS/`): iOS-specific UI code
  - `GameViewController.swift`: UIViewController-based wrapper for SceneKit view
  - Touch gesture handling for node interaction

- **macOS Module** (`Yunorix – Reborn Beyond the Nexus macOS/`): macOS-specific UI code  
  - `GameViewController.swift`: NSViewController-based wrapper for SceneKit view
  - Click gesture handling for node interaction

### Key Design Patterns
- **Cross-platform abstraction**: `SCNColor` typealias for platform-specific color types
- **Shared game logic**: `GameController` handles scene setup, rendering, and interaction
- **Platform-specific input**: Separate gesture handling for touch (iOS) vs click (macOS)
- **Scene graph**: Uses SceneKit's node hierarchy with named node lookup

### Game Features
- 3D ship model with continuous rotation animation
- Interactive node highlighting on tap/click with emission color animation
- Camera manipulation controls
- Debug statistics display
- Cross-platform gesture recognition

## Development Notes

- Uses `@MainActor` for thread safety in GameController
- Scene loading expects `ship.scn` asset with a child node named "ship"
- Platform differences handled through compiler directives (`#if os(macOS)`)
- All SceneKit rendering happens on dedicated renderer thread