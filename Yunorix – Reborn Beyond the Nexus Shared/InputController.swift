//
//  InputController.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - Input Controller

@MainActor
class InputController: ObservableObject {
    
    // MARK: - Input State
    
    @Published var isDragging: Bool = false
    @Published var lastPanLocation: CGPoint = .zero
    @Published var cameraRotation: Double = 0
    @Published var cameraZoom: Double = 8.0
    
    // MARK: - Game References
    
    weak var gameScene: GameScene?
    weak var playerController: PlayerNode?
    weak var uiManager: UIManager?
    
    // MARK: - Touch/Mouse Handling
    
    func handleTap(at location: CGPoint, in sceneView: SCNView) {
        let hitTest = sceneView.hitTest(location, options: [:])
        
        if let hit = hitTest.first {
            let worldPosition = hit.worldCoordinates
            
            // Check if we hit a character
            if let character = findCharacterAtPosition(worldPosition) {
                selectCharacter(character)
            } else {
                // Move player to location
                movePlayerToLocation(worldPosition)
            }
        }
    }
    
    func handleLongPress(at location: CGPoint, in sceneView: SCNView) {
        let hitTest = sceneView.hitTest(location, options: [:])
        
        if let hit = hitTest.first {
            let worldPosition = hit.worldCoordinates
            
            // Check if we hit an enemy for attack
            if let enemy = findEnemyAtPosition(worldPosition) {
                attackEnemy(enemy)
            }
        }
    }
    
    func handlePan(translation: CGPoint, velocity: CGPoint) {
        guard let gameScene = gameScene else { return }
        
        // Camera rotation with pan gesture
        let rotationSpeed: Double = 0.01
        let newRotation = cameraRotation + Double(translation.x) * rotationSpeed
        
        cameraRotation = newRotation
        gameScene.setCameraAngle(newRotation)
        
        isDragging = true
    }
    
    func handlePanEnded() {
        isDragging = false
    }
    
    func handlePinch(scale: CGFloat) {
        guard let gameScene = gameScene else { return }
        
        let zoomSpeed: Double = 2.0
        let newZoom = max(3.0, min(15.0, cameraZoom - Double(scale - 1.0) * zoomSpeed))
        
        cameraZoom = newZoom
        gameScene.setCameraDistance(newZoom)
    }
    
    // MARK: - Keyboard Input (macOS)
    
    #if os(macOS)
    func handleKeyPress(_ event: NSEvent) {
        guard let gameScene = gameScene,
              let playerController = playerController else { return }
        
        switch event.keyCode {
        case 13: // W
            movePlayer(direction: .north)
        case 1: // S
            movePlayer(direction: .south)
        case 0: // A
            movePlayer(direction: .west)
        case 2: // D
            movePlayer(direction: .east)
        case 49: // Space
            uiManager?.performPlayerAction(.wait)
        default:
            break
        }
    }
    #endif
    
    // MARK: - Character Interaction
    
    private func findCharacterAtPosition(_ position: SCNVector3) -> SceneKitCharacter? {
        guard let gameScene = gameScene else { return nil }
        
        let threshold: Float = 1.5
        
        // Check player
        if let player = gameScene.playerCharacter {
            let distance = simd_distance(simd_float3(player.worldPosition), simd_float3(position))
            if distance < threshold {
                return player
            }
        }
        
        // Check enemies
        for enemy in gameScene.enemies {
            let distance = simd_distance(simd_float3(enemy.worldPosition), simd_float3(position))
            if distance < threshold {
                return enemy
            }
        }
        
        return nil
    }
    
    private func findEnemyAtPosition(_ position: SCNVector3) -> SceneKitEnemy? {
        guard let gameScene = gameScene else { return nil }
        
        let threshold: Float = 1.5
        
        for enemy in gameScene.enemies {
            let distance = simd_distance(simd_float3(enemy.worldPosition), simd_float3(position))
            if distance < threshold {
                return enemy
            }
        }
        
        return nil
    }
    
    private func selectCharacter(_ character: SceneKitCharacter) {
        // Deselect all characters first
        gameScene?.playerCharacter?.setSelected(false)
        gameScene?.enemies.forEach { $0.setSelected(false) }
        
        // Select the new character
        character.setSelected(true)
        uiManager?.selectTarget(character)
        
        print("🎯 Selected: \(character.name)")
    }
    
    private func movePlayerToLocation(_ position: SCNVector3) {
        guard let playerController = playerController else { return }
        
        let adjustedPosition = SCNVector3(position.x, 0, position.z)
        playerController.moveHero(to: adjustedPosition)
        
        uiManager?.addMessage("🚶 Moving to location", type: .info)
    }
    
    private func attackEnemy(_ enemy: SceneKitEnemy) {
        guard let playerController = playerController else { return }
        
        playerController.attackTarget(enemy)
        uiManager?.addMessage("⚔️ Attacking \(enemy.name)!", type: .combat)
    }
    
    // MARK: - Movement Controls
    
    private func movePlayer(direction: MovementDirection) {
        uiManager?.performPlayerAction(.move(direction))
    }
    
    // MARK: - Camera Controls
    
    func resetCamera() {
        guard let gameScene = gameScene else { return }
        
        cameraRotation = 0
        cameraZoom = 8.0
        
        gameScene.setCameraAngle(0)
        gameScene.setCameraDistance(8.0)
        gameScene.cameraFollowsPlayer = true
    }
    
    func toggleCameraFollow() {
        guard let gameScene = gameScene else { return }
        gameScene.cameraFollowsPlayer.toggle()
    }
    
    // MARK: - Game State Integration
    
    func connectToGame(scene: GameScene, player: PlayerNode, ui: UIManager) {
        self.gameScene = scene
        self.playerController = player
        self.uiManager = ui
    }
    
    // MARK: - Input Configuration
    
    func enableGameplayInput() {
        // Enable all input modes for gameplay
    }
    
    func disableGameplayInput() {
        // Disable input during cutscenes, menus, etc.
    }
    
    // MARK: - Gesture Recognizer Setup
    
    func setupGestureRecognizers(for sceneView: SCNView) {
        #if !os(macOS)
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(longPressGesture)
        
        // Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        #endif
    }
    
    #if !os(macOS)
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard let sceneView = gesture.view as? SCNView else { return }
        let location = gesture.location(in: sceneView)
        handleTap(at: location, in: sceneView)
    }
    
    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let sceneView = gesture.view as? SCNView else { return }
        let location = gesture.location(in: sceneView)
        handleLongPress(at: location, in: sceneView)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let sceneView = gesture.view as? SCNView else { return }
        
        let translation = gesture.translation(in: sceneView)
        let velocity = gesture.velocity(in: sceneView)
        
        switch gesture.state {
        case .began, .changed:
            handlePan(translation: translation, velocity: velocity)
        case .ended, .cancelled:
            handlePanEnded()
        default:
            break
        }
        
        gesture.setTranslation(.zero, in: sceneView)
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        handlePinch(scale: gesture.scale)
        gesture.scale = 1.0
    }
    #endif
}

// MARK: - Touch Areas for UI

struct GameControlOverlay: View {
    @ObservedObject var inputController: InputController
    @ObservedObject var uiManager: UIManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Movement controls (bottom left)
                VStack {
                    Spacer()
                    HStack {
                        MovementControlsView(inputController: inputController, uiManager: uiManager)
                        Spacer()
                    }
                }
                .padding()
                
                // Action buttons (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ActionButtonsView(uiManager: uiManager)
                    }
                }
                .padding()
                
                // Player stats (top left)
                VStack {
                    HStack {
                        PlayerStatsView(uiManager: uiManager)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
                
                // Target info (top right)
                VStack {
                    HStack {
                        Spacer()
                        if uiManager.selectedTarget != nil {
                            TargetInfoView(uiManager: uiManager)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                // Message log (bottom center)
                VStack {
                    Spacer()
                    MessageLogView(uiManager: uiManager)
                }
            }
        }
    }
}

struct MovementControlsView: View {
    @ObservedObject var inputController: InputController
    @ObservedObject var uiManager: UIManager
    
    var body: some View {
        VStack(spacing: 5) {
            Button("↑") {
                uiManager.performPlayerAction(.move(.north))
            }
            .buttonStyle(MovementButtonStyle())
            
            HStack(spacing: 5) {
                Button("←") {
                    uiManager.performPlayerAction(.move(.west))
                }
                .buttonStyle(MovementButtonStyle())
                
                Button("↓") {
                    uiManager.performPlayerAction(.move(.south))
                }
                .buttonStyle(MovementButtonStyle())
                
                Button("→") {
                    uiManager.performPlayerAction(.move(.east))
                }
                .buttonStyle(MovementButtonStyle())
            }
        }
    }
}

struct MovementButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.7))
            .foregroundStyle(.white)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
    }
}

struct TargetInfoView: View {
    @ObservedObject var uiManager: UIManager
    
    var body: some View {
        if let target = uiManager.selectedTarget {
            VStack(alignment: .trailing, spacing: 8) {
                Text(target.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack {
                        Text("HP")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text("\(Int(target.healthPoints))/\(Int(target.maxHealthPoints))")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    
                    ProgressView(value: uiManager.getTargetHealthPercentage())
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
        }
    }
}