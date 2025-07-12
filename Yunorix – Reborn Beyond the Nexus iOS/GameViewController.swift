//
//  GameViewController.swift
//  Yunorix – Reborn Beyond the Nexus iOS
//
//  Created by NMK Solutions on 12.07.25.
//

import UIKit
import SceneKit
import SwiftUI
import Combine

/// Professional Game View Controller
/// Manages the complete 3D RPG experience with dual rendering system:
/// 1. Legacy RPG system for compatibility
/// 2. New SceneKit system for 3D visualization
class GameViewController: UIViewController {
    
    // MARK: - Core Properties
    
    var gameView: SCNView {
        return self.view as! SCNView
    }
    
    // Legacy system
    private var legacyGameController: GameController!
    private var rpgUIHostingController: UIHostingController<RPGUIView>?
    
    // New professional system
    private let gameMaster = GameMaster.shared
    private var sceneKitController: GameIntegration.GameController!
    private var modernUIController: UIHostingController<GameView>?
    
    // System state
    private var isUsingModernRenderer: Bool = false
    private var subscriptions = Set<AnyCancellable>()
    
    // Performance monitoring
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastFrameTime: CFTimeInterval = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProfessionalGameSystem()
        setupPerformanceMonitoring()
        setupGestureRecognizers()
        observeGameState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start game systems
        if isUsingModernRenderer {
            resumeModernSystem()
        } else {
            resumeLegacySystem()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Pause game systems
        gameMaster.pauseGame()
        gameView.scene?.isPaused = true
    }
    
    // MARK: - Professional System Setup
    
    private func setupProfessionalGameSystem() {
        print("🎮 Setting up professional game system...")
        
        // Initialize legacy system first (for compatibility)
        setupLegacySystem()
        
        // Initialize modern system
        setupModernSystem()
        
        // Default to modern system
        switchToModernRenderer()
    }
    
    private func setupLegacySystem() {
        // Configure legacy SceneKit view
        configureSceneView()
        
        // Initialize legacy game controller
        legacyGameController = GameController(sceneRenderer: gameView)
        
        // Setup legacy UI
        setupLegacyUI()
    }
    
    private func setupModernSystem() {
        // Initialize modern SceneKit controller
        sceneKitController = GameIntegration.GameController()
        
        // Connect to GameMaster
        gameMaster.sceneKitRenderer = ModernSceneKitRenderer(controller: sceneKitController)
    }
    
    private func configureSceneView() {
        gameView.allowsCameraControl = false // Professional camera control
        gameView.showsStatistics = true
        gameView.backgroundColor = UIColor.black
        gameView.autoenablesDefaultLighting = false
        gameView.antialiasingMode = .multisampling4X
        gameView.preferredFramesPerSecond = 60
        
        // Professional rendering settings
        gameView.jitteringEnabled = true
        gameView.temporalAntialiasingEnabled = true
    }
    
    // MARK: - Dual Rendering System
    
    func switchToModernRenderer() {
        print("🚀 Switching to modern SceneKit renderer")
        
        isUsingModernRenderer = true
        
        // Hide legacy UI
        rpgUIHostingController?.view.isHidden = true
        
        // Show modern UI
        showModernUI()
        
        // Switch scene
        gameView.scene = sceneKitController.gameScene.scene
        gameView.delegate = self
        
        // Start GameMaster
        gameMaster.startNewGame()
    }
    
    func switchToLegacyRenderer() {
        print("🔄 Switching to legacy RPG renderer")
        
        isUsingModernRenderer = false
        
        // Hide modern UI
        modernUIController?.view.isHidden = true
        
        // Show legacy UI
        rpgUIHostingController?.view.isHidden = false
        
        // Switch scene back
        gameView.scene = legacyGameController.gameScene
        gameView.delegate = nil
    }
    
    // MARK: - UI Management
    
    private func setupLegacyUI() {
        let rpgUIView = RPGUIView(gameController: legacyGameController)
        rpgUIHostingController = UIHostingController(rootView: rpgUIView)
        
        guard let hostingController = rpgUIHostingController else { return }
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        setupConstraints(for: hostingController.view)
        hostingController.view.backgroundColor = UIColor.clear
    }
    
    private func showModernUI() {
        guard modernUIController == nil else {
            modernUIController?.view.isHidden = false
            return
        }
        
        let gameView = GameView()
        modernUIController = UIHostingController(rootView: gameView)
        
        guard let hostingController = modernUIController else { return }
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        setupConstraints(for: hostingController.view)
        hostingController.view.backgroundColor = UIColor.clear
    }
    
    private func setupConstraints(for hostingView: UIView) {
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Performance Monitoring
    
    private func setupPerformanceMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updatePerformanceMetrics))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updatePerformanceMetrics() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastFrameTime >= 1.0 {
            let fps = Double(frameCount) / (currentTime - lastFrameTime)
            
            // Update GameMaster metrics
            DispatchQueue.main.async {
                self.gameMaster.frameRate = fps
            }
            
            frameCount = 0
            lastFrameTime = currentTime
        }
    }
    
    // MARK: - Game State Observation
    
    private func observeGameState() {
        gameMaster.$gameState
            .sink { [weak self] state in
                self?.handleGameStateChange(state)
            }
            .store(in: &subscriptions)
    }
    
    private func handleGameStateChange(_ state: GameState) {
        switch state {
        case .playing:
            resumeCurrentSystem()
        case .paused:
            pauseCurrentSystem()
        case .gameOver:
            handleGameOver()
        case .error(let message):
            showError(message)
        default:
            break
        }
    }
    
    // MARK: - System Control
    
    private func resumeCurrentSystem() {
        if isUsingModernRenderer {
            resumeModernSystem()
        } else {
            resumeLegacySystem()
        }
    }
    
    private func pauseCurrentSystem() {
        gameView.scene?.isPaused = true
    }
    
    private func resumeModernSystem() {
        gameView.scene?.isPaused = false
        sceneKitController.inputController.enableGameplayInput()
    }
    
    private func resumeLegacySystem() {
        gameView.scene?.isPaused = false
    }
    
    // MARK: - Gesture Recognition
    
    private func setupGestureRecognizers() {
        // Triple tap to switch renderers (debug feature)
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
        tripleTap.numberOfTapsRequired = 3
        gameView.addGestureRecognizer(tripleTap)
        
        // Long press for debug menu
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleDebugLongPress))
        longPress.minimumPressDuration = 2.0
        gameView.addGestureRecognizer(longPress)
        
        // Setup modern gesture system
        if isUsingModernRenderer {
            sceneKitController.inputController.setupGestureRecognizers(for: gameView)
        }
    }
    
    @objc private func handleTripleTap() {
        // Toggle between rendering systems
        if isUsingModernRenderer {
            switchToLegacyRenderer()
        } else {
            switchToModernRenderer()
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    @objc private func handleDebugLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        showProfessionalDebugMenu()
    }
    
    // MARK: - Debug Interface
    
    private func showProfessionalDebugMenu() {
        let alert = UIAlertController(
            title: "🔧 Professional Debug Menu",
            message: gameMaster.getSystemStatus(),
            preferredStyle: .actionSheet
        )
        
        // Renderer selection
        alert.addAction(UIAlertAction(title: "🎨 Switch Renderer", style: .default) { _ in
            self.handleTripleTap()
        })
        
        // Performance analysis
        alert.addAction(UIAlertAction(title: "📊 Performance Analysis", style: .default) { _ in
            self.showPerformanceAnalysis()
        })
        
        // Memory debug
        alert.addAction(UIAlertAction(title: "🧠 Memory Debug", style: .default) { _ in
            self.analyzeMemoryUsage()
        })
        
        // Asset inspector
        alert.addAction(UIAlertAction(title: "📦 Asset Inspector", style: .default) { _ in
            self.showAssetInspector()
        })
        
        // Game state manipulation
        alert.addAction(UIAlertAction(title: "🎮 Game State", style: .default) { _ in
            self.showGameStateMenu()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Position for iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = gameView
            popover.sourceRect = CGRect(
                x: gameView.bounds.midX,
                y: gameView.bounds.midY,
                width: 0,
                height: 0
            )
        }
        
        present(alert, animated: true)
    }
    
    private func showPerformanceAnalysis() {
        let analysis = """
        === Performance Analysis ===
        Frame Rate: \(String(format: "%.1f", gameMaster.frameRate)) FPS
        Memory Usage: \(String(format: "%.1f", gameMaster.memoryUsage)) MB
        Render Time: \(String(format: "%.3f", gameMaster.renderTime)) ms
        Renderer: \(isUsingModernRenderer ? "Modern" : "Legacy")
        Scene Complexity: \(gameView.scene?.rootNode.childNodes.count ?? 0) nodes
        """
        
        showInfoAlert(title: "📊 Performance", message: analysis)
    }
    
    private func analyzeMemoryUsage() {
        let memoryInfo = """
        === Memory Analysis ===
        Physical Memory: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB
        Available Memory: \(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) MB
        Scene Memory: Calculating...
        Asset Cache: \(AssetManager.shared.getAssetsByCategory(.nature).count) items
        """
        
        showInfoAlert(title: "🧠 Memory", message: memoryInfo)
    }
    
    private func showAssetInspector() {
        let assetInfo = """
        === Asset Inspector ===
        Nature Assets: \(AssetManager.shared.getAssetsByCategory(.nature).count)
        Character Assets: \(AssetManager.shared.getAssetsByCategory(.character).count)
        UI Assets: \(AssetManager.shared.getAssetsByCategory(.ui).count)
        Cache Status: Active
        Load Status: Ready
        """
        
        showInfoAlert(title: "📦 Assets", message: assetInfo)
    }
    
    private func showGameStateMenu() {
        let alert = UIAlertController(title: "🎮 Game State", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Start New Game", style: .default) { _ in
            self.gameMaster.startNewGame()
        })
        
        alert.addAction(UIAlertAction(title: "Pause Game", style: .default) { _ in
            self.gameMaster.pauseGame()
        })
        
        alert.addAction(UIAlertAction(title: "Resume Game", style: .default) { _ in
            self.gameMaster.resumeGame()
        })
        
        alert.addAction(UIAlertAction(title: "Reset Game", style: .destructive) { _ in
            self.gameMaster.resetGame()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = gameView
            popover.sourceRect = CGRect(x: gameView.bounds.midX, y: gameView.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func showInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Error Handling
    
    private func handleGameOver() {
        let alert = UIAlertController(
            title: "💀 Game Over",
            message: "Your heroes have fallen! What would you like to do?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Restart", style: .default) { _ in
            self.gameMaster.startNewGame()
        })
        
        alert.addAction(UIAlertAction(title: "Main Menu", style: .default) { _ in
            self.gameMaster.transitionToScene(.mainMenu)
        })
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "❌ Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - View Controller Configuration
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }
    
    override var prefersStatusBarHidden: Bool {
        return false // Keep status bar for professional UI
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true // Auto-hide for immersive experience
    }
    
    // MARK: - Memory Management
    
    deinit {
        displayLink?.invalidate()
        rpgUIHostingController?.removeFromParent()
        modernUIController?.removeFromParent()
        subscriptions.removeAll()
    }
}

// MARK: - SCNSceneRendererDelegate

extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard isUsingModernRenderer else { return }
        
        Task { @MainActor in
            gameMaster.update(deltaTime: time)
            sceneKitController.update(atTime: time)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        // Professional post-render processing
        DispatchQueue.main.async {
            self.gameMaster.renderTime = (CACurrentMediaTime() - time) * 1000
        }
    }
}

// MARK: - Modern SceneKit Renderer Adapter

class ModernSceneKitRenderer: SceneKitRenderer {
    private let controller: GameIntegration.GameController
    
    init(controller: GameIntegration.GameController) {
        self.controller = controller
        super.init()
    }
    
    override func pauseRendering() {
        controller.pauseGame()
    }
    
    override func resumeRendering() {
        controller.resumeGame()
    }
}