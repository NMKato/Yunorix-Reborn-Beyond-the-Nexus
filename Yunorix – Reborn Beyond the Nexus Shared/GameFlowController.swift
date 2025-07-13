//
//  GameFlowController.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

enum GameState {
    case intro
    case mainMenu  
    case characterSelection
    case tutorial
    case openWorld
    case paused
    case gameOver
}

@MainActor
class GameFlowController: ObservableObject {
    
    @Published var currentState: GameState = .intro
    @Published var selectedCharacter: HeroClass = .mage
    @Published var showDebugInfo = false
    
    // Game systems
    private var openWorldController: OpenWorldController?
    var tutorialController: TutorialController?
    
    // MARK: - State Management
    
    func transitionTo(_ newState: GameState) {
        print("🎮 GameFlow: Transitioning from \(currentState) to \(newState)")
        
        // Cleanup current state
        cleanupCurrentState()
        
        // Setup new state
        currentState = newState
        setupNewState()
    }
    
    private func cleanupCurrentState() {
        switch currentState {
        case .openWorld:
            openWorldController = nil
        case .tutorial:
            tutorialController = nil
        default:
            break
        }
    }
    
    private func setupNewState() {
        switch currentState {
        case .intro:
            setupIntro()
        case .mainMenu:
            setupMainMenu()
        case .characterSelection:
            setupCharacterSelection()
        case .tutorial:
            setupTutorial()
        case .openWorld:
            setupOpenWorld()
        case .paused:
            pauseCurrentGame()
        case .gameOver:
            handleGameOver()
        }
    }
    
    // MARK: - State Setup Methods
    
    private func setupIntro() {
        // Intro will auto-advance to main menu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Allow manual skip or auto-advance
        }
    }
    
    private func setupMainMenu() {
        // Main menu is ready
        print("📋 Main menu ready")
    }
    
    private func setupCharacterSelection() {
        // Character selection ready
        print("👤 Character selection ready")
    }
    
    private func setupTutorial() {
        tutorialController = TutorialController()
        tutorialController?.onTutorialComplete = { [weak self] in
            self?.transitionTo(.openWorld)
        }
    }
    
    private func setupOpenWorld() {
        openWorldController = OpenWorldController()
        print("🌍 Open world initialized")
    }
    
    private func pauseCurrentGame() {
        // Pause current game systems
        openWorldController?.stopMovement()
        print("⏸️ Game paused")
    }
    
    private func handleGameOver() {
        // Show game over screen and reset
        print("💀 Game Over")
    }
    
    // MARK: - User Actions
    
    func startNewGame() {
        transitionTo(.characterSelection)
    }
    
    func continueGame() {
        // Load saved game and go to open world
        transitionTo(.openWorld)
    }
    
    func selectCharacter(_ character: HeroClass) {
        selectedCharacter = character
        transitionTo(.tutorial)
    }
    
    func skipTutorial() {
        transitionTo(.openWorld)
    }
    
    func pauseGame() {
        if currentState == .openWorld {
            transitionTo(.paused)
        }
    }
    
    func resumeGame() {
        if currentState == .paused {
            transitionTo(.openWorld)
        }
    }
    
    func returnToMainMenu() {
        transitionTo(.mainMenu)
    }
    
    func toggleDebugInfo() {
        showDebugInfo.toggle()
    }
}

// MARK: - Tutorial Controller

@MainActor
class TutorialController: ObservableObject {
    
    @Published var currentStep = 0
    @Published var tutorialText = ""
    @Published var showSkipButton = true
    
    var onTutorialComplete: (() -> Void)?
    
    let tutorialSteps = [
        "Welcome to Yunorix! This is an open world adventure.",
        "Use WASD keys or touch controls to move around the world.",
        "Collect yellow gems to gain magical essence and restore mana.",
        "Avoid red enemies or fight them if you're feeling brave!",
        "Explore the magical portals to discover new areas.",
        "Your health and mana are shown in the UI overlay.",
        "That's it! You're ready to explore the open world!"
    ]
    
    init() {
        startTutorial()
    }
    
    private func startTutorial() {
        currentStep = 0
        showNextStep()
    }
    
    func nextStep() {
        currentStep += 1
        if currentStep < tutorialSteps.count {
            showNextStep()
        } else {
            completeTutorial()
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
    
    private func showNextStep() {
        tutorialText = tutorialSteps[currentStep]
    }
    
    private func completeTutorial() {
        onTutorialComplete?()
    }
    
    var isComplete: Bool {
        return currentStep >= tutorialSteps.count
    }
    
    var progress: Float {
        return Float(currentStep) / Float(tutorialSteps.count)
    }
}

// MARK: - Main Game View

struct GameFlowView: View {
    @StateObject private var gameFlow = GameFlowController()
    @StateObject private var openWorldController = OpenWorldController()
    
    var body: some View {
        ZStack {
            // Main game content based on state
            switch gameFlow.currentState {
            case .intro:
                IntroScreen {
                    gameFlow.transitionTo(.mainMenu)
                }
                
            case .mainMenu:
                MainMenuScreen(
                    onStartGame: {
                        gameFlow.startNewGame()
                    },
                    onLoadGame: {
                        gameFlow.continueGame()
                    }
                )
                
            case .characterSelection:
                CharacterSelectionView { character in
                    gameFlow.selectCharacter(character)
                }
                
            case .tutorial:
                TutorialView(controller: gameFlow.tutorialController!) {
                    gameFlow.skipTutorial()
                }
                
            case .openWorld:
                OpenWorldView(controller: openWorldController)
                
            case .paused:
                PauseMenuView(
                    onResume: { gameFlow.resumeGame() },
                    onMainMenu: { gameFlow.returnToMainMenu() }
                )
                
            case .gameOver:
                GameOverView(
                    onRestart: { gameFlow.startNewGame() },
                    onMainMenu: { gameFlow.returnToMainMenu() }
                )
            }
            
            // Debug overlay
            if gameFlow.showDebugInfo {
                DebugOverlay(gameFlow: gameFlow, openWorld: openWorldController)
            }
        }
        .onAppear {
            gameFlow.transitionTo(.intro)
        }
    }
}

// MARK: - Tutorial View

struct TutorialView: View {
    @ObservedObject var controller: TutorialController
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Tutorial content
                VStack(spacing: 20) {
                    Text("Tutorial")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Step \(controller.currentStep + 1) of \(controller.tutorialSteps.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(controller.tutorialText)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Progress bar
                    ProgressView(value: controller.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .frame(width: 200)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    if controller.showSkipButton {
                        Button("Skip Tutorial") {
                            onSkip()
                        }
                        .foregroundColor(.gray)
                    }
                    
                    Button(controller.isComplete ? "Start Adventure!" : "Next") {
                        controller.nextStep()
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Open World View

struct OpenWorldView: View {
    @ObservedObject var controller: OpenWorldController
    @State private var inputVector = CGPoint.zero
    
    var body: some View {
        ZStack {
            // SceneKit view
            SceneKitView(controller: controller, inputVector: $inputVector)
                .ignoresSafeArea()
            
            // UI Overlay
            OpenWorldUIOverlay(controller: controller, inputVector: $inputVector)
        }
    }
}

struct SceneKitView: UIViewRepresentable {
    let controller: OpenWorldController
    @Binding var inputVector: CGPoint
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        controller.setupOpenWorld(in: sceneView)
        
        // Add gesture recognizers for movement
        setupGestures(sceneView)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        controller.updateMovement(inputVector: inputVector)
    }
    
    private func setupGestures(_ sceneView: SCNView) {
        #if os(iOS)
        // Pan gesture for movement
        let panGesture = UIPanGestureRecognizer { gesture in
            let translation = gesture.translation(in: sceneView)
            let _ = gesture.velocity(in: sceneView)
            
            switch gesture.state {
            case .changed:
                inputVector = CGPoint(
                    x: translation.x / 100.0,
                    y: -translation.y / 100.0
                )
            case .ended, .cancelled:
                inputVector = .zero
            default:
                break
            }
        }
        
        sceneView.addGestureRecognizer(panGesture)
        #endif
    }
}

// MARK: - UI Overlays

struct OpenWorldUIOverlay: View {
    @ObservedObject var controller: OpenWorldController
    @Binding var inputVector: CGPoint
    
    var body: some View {
        VStack {
            // Top HUD
            topHUD
            
            Spacer()
            
            // Bottom controls
            bottomControls
        }
        .padding()
    }
    
    private var topHUD: some View {
        HStack {
            // Player stats
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    ProgressView(value: controller.playerHealth, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(width: 100)
                    Text("\(Int(controller.playerHealth))")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.blue)
                    ProgressView(value: controller.playerMana, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 100)
                    Text("\(Int(controller.playerMana))")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                Text("Items: \(controller.collectedItems)")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            
            Spacer()
            
            // Position info
            VStack(alignment: .trailing) {
                Text("X: \(Int(controller.playerPosition.x))")
                Text("Z: \(Int(controller.playerPosition.z))")
            }
            .foregroundColor(.white.opacity(0.7))
            .font(.caption)
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 15) {
            // Game message
            Text(controller.gameMessage)
                .foregroundColor(.white)
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            
            // Movement controls (for devices without keyboard)
            #if os(iOS)
            HStack(spacing: 20) {
                // Virtual D-pad
                VStack {
                    Button("↑") {
                        inputVector = CGPoint(x: 0, y: 1)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            inputVector = .zero
                        }
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    
                    HStack {
                        Button("←") {
                            inputVector = CGPoint(x: -1, y: 0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                inputVector = .zero
                            }
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        
                        Button("→") {
                            inputVector = CGPoint(x: 1, y: 0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                inputVector = .zero
                            }
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                    }
                    
                    Button("↓") {
                        inputVector = CGPoint(x: 0, y: -1)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            inputVector = .zero
                        }
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            #endif
        }
    }
}

// MARK: - Pause and Game Over Views

struct PauseMenuView: View {
    let onResume: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Game Paused")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Button("Resume") {
                        onResume()
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    
                    Button("Main Menu") {
                        onMainMenu()
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 50)
            }
        }
    }
}

struct GameOverView: View {
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Game Over")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("Your adventure has ended...")
                    .font(.title3)
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Button("New Adventure") {
                        onRestart()
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    
                    Button("Main Menu") {
                        onMainMenu()
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 50)
            }
        }
    }
}

// MARK: - Debug Overlay

struct DebugOverlay: View {
    @ObservedObject var gameFlow: GameFlowController
    @ObservedObject var openWorld: OpenWorldController
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("DEBUG")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("State: \(String(describing: gameFlow.currentState))")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    if gameFlow.currentState == .openWorld {
                        Text("Pos: (\(Int(openWorld.playerPosition.x)), \(Int(openWorld.playerPosition.z)))")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Items: \(openWorld.collectedItems)")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Health: \(Int(openWorld.playerHealth))")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Button("Close") {
                        gameFlow.toggleDebugInfo()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
}
