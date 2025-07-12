//
//  GameIntegration.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

// MARK: - Main Game Integration

@MainActor
class GameController: ObservableObject {
    
    // MARK: - Core Systems
    
    @Published var gameScene: GameScene
    @Published var playerController: PlayerNode
    @Published var uiManager: UIManager
    @Published var inputController: InputController
    
    // MARK: - Game State
    
    @Published var isGameInitialized: Bool = false
    @Published var isGameRunning: Bool = false
    @Published var currentGameMode: GameMode = .menu
    
    // MARK: - Initialization
    
    init() {
        // Initialize core systems
        self.gameScene = GameScene()
        self.playerController = PlayerNode()
        self.uiManager = UIManager()
        self.inputController = InputController()
        
        // Connect systems
        connectSystems()
    }
    
    private func connectSystems() {
        // Connect UI manager to game systems
        uiManager.gameScene = gameScene
        uiManager.playerController = playerController
        uiManager.currentPlayer = gameScene.playerCharacter
        
        // Connect input controller
        inputController.connectToGame(
            scene: gameScene,
            player: playerController,
            ui: uiManager
        )
        
        // Set player controller's hero
        if let player = gameScene.playerCharacter {
            playerController.setHero(player)
        }
        
        isGameInitialized = true
    }
    
    // MARK: - Game Lifecycle
    
    func startGame() {
        guard isGameInitialized else { return }
        
        Task {
            await gameScene.preloadAssets()
            
            await MainActor.run {
                isGameRunning = true
                currentGameMode = .playing
                uiManager.addMessage("🎮 Game started!", type: .system)
            }
        }
    }
    
    func pauseGame() {
        isGameRunning = false
        currentGameMode = .paused
        uiManager.addMessage("⏸️ Game paused", type: .system)
    }
    
    func resumeGame() {
        isGameRunning = true
        currentGameMode = .playing
        uiManager.addMessage("▶️ Game resumed", type: .system)
    }
    
    func stopGame() {
        isGameRunning = false
        currentGameMode = .menu
        uiManager.addMessage("🛑 Game stopped", type: .system)
    }
    
    // MARK: - Game Updates
    
    func update(atTime time: TimeInterval) {
        guard isGameRunning else { return }
        gameScene.update(atTime: time)
    }
    
    // MARK: - Debug Functions
    
    func getSystemStatus() -> String {
        var status = ["=== System Status ==="]
        status.append("Game Initialized: \(isGameInitialized)")
        status.append("Game Running: \(isGameRunning)")
        status.append("Game Mode: \(currentGameMode)")
        status.append("Assets Ready: \(gameScene.isGameReady)")
        
        if let player = gameScene.playerCharacter {
            status.append("Player: \(player.name)")
            status.append("Player Position: \(player.worldPosition)")
        }
        
        status.append("Enemies: \(gameScene.enemies.count)")
        status.append("World Objects: \(gameScene.worldNodes.count)")
        
        return status.joined(separator: "\n")
    }
}

// MARK: - Game Modes

enum GameMode {
    case menu
    case playing
    case paused
    case gameOver
}

// MARK: - Main Game View

struct GameView: View {
    @StateObject private var gameController = GameController()
    @State private var showDebugInfo = false
    
    var body: some View {
        ZStack {
            // 3D Scene View
            SceneKitView(gameController: gameController)
                .ignoresSafeArea()
            
            // Game UI Overlay
            if gameController.isGameRunning {
                GameControlOverlay(
                    inputController: gameController.inputController,
                    uiManager: gameController.uiManager
                )
            }
            
            // Debug Info
            if showDebugInfo {
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(gameController.getSystemStatus())
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            
                            Text(gameController.gameScene.getDebugInfo())
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            
            // Menu Overlay
            if gameController.currentGameMode == .menu {
                MenuView(gameController: gameController)
            }
        }
        .onAppear {
            gameController.startGame()
        }
        .onTapGesture(count: 2) {
            showDebugInfo.toggle()
        }
    }
}

// MARK: - SceneKit View Wrapper

struct SceneKitView: View {
    let gameController: GameController
    
    var body: some View {
        SceneKitViewRepresentable(gameController: gameController)
    }
}

// MARK: - SceneKit View Representable

struct SceneKitViewRepresentable {
    let gameController: GameController
}

#if os(macOS)
extension SceneKitViewRepresentable: NSViewRepresentable {
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = gameController.gameScene.scene
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = context.coordinator
        
        return sceneView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gameController)
    }
}
#else
extension SceneKitViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = gameController.gameScene.scene
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = context.coordinator
        
        // Setup gesture recognizers
        gameController.inputController.setupGestureRecognizers(for: sceneView)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gameController)
    }
}
#endif

// MARK: - SceneKit View Coordinator

class Coordinator: NSObject, SCNSceneRendererDelegate {
    private let gameController: GameController
    
    init(_ gameController: GameController) {
        self.gameController = gameController
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        Task { @MainActor in
            gameController.update(atTime: time)
        }
    }
}

// MARK: - Menu View

struct MenuView: View {
    let gameController: GameController
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Yunorix")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Reborn Beyond the Nexus")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
            
            VStack(spacing: 15) {
                Button("Start Game") {
                    gameController.startGame()
                }
                .buttonStyle(MenuButtonStyle())
                
                Button("Settings") {
                    // Settings functionality
                }
                .buttonStyle(MenuButtonStyle())
                
                Button("Exit") {
                    // Exit functionality
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(width: 200)
            .background(Color.blue.opacity(0.8))
            .foregroundStyle(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Preview

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}