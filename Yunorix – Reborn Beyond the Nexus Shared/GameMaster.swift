//
//  GameMaster.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation
import SceneKit
import SwiftUI

// MARK: - Professional Game System Architecture

@MainActor
class GameMaster: ObservableObject {
    
    // MARK: - Core Systems (Singleton Pattern)
    
    static let shared = GameMaster()
    
    // MARK: - System Managers
    
    @Published var gameState: GameState = .initializing
    @Published var currentScene: GameSceneType = .mainMenu
    
    // Core game systems
    private(set) var sceneManager: SceneManager!
    private(set) var assetManager: AssetManager = AssetManager.shared
    private(set) var audioManager: AudioManager!
    private(set) var inputManager: InputManager!
    private(set) var uiManager: UIManager!
    private(set) var saveManager: SaveManager!
    
    // RPG Systems
    private(set) var heroManager: HeroManager!
    private(set) var combatManager: CombatManager!
    private(set) var inventoryManager: InventoryManager!
    
    // 3D Systems
    private(set) var sceneKitRenderer: SceneKitRenderer!
    
    // MARK: - Game Data
    
    @Published var currentParty: [Hero] = []
    @Published var currentEnemies: [Enemy] = []
    @Published var isInCombat: Bool = false
    @Published var gameSettings: GameSettings = GameSettings()
    
    // MARK: - Performance Metrics
    
    @Published var frameRate: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var renderTime: Double = 0.0
    
    // MARK: - Initialization
    
    private init() {
        setupSystems()
    }
    
    private func setupSystems() {
        print("🎮 GameMaster: Initializing professional game systems...")
        
        // Initialize managers in dependency order
        audioManager = AudioManager()
        inputManager = InputManager()
        uiManager = UIManager()
        saveManager = SaveManager()
        
        // RPG Managers
        heroManager = HeroManager()
        combatManager = CombatManager()
        inventoryManager = InventoryManager()
        
        // 3D Renderer
        sceneKitRenderer = SceneKitRenderer()
        sceneManager = SceneManager(renderer: sceneKitRenderer)
        
        // Connect systems
        connectSystems()
        
        gameState = .ready
        print("✅ GameMaster: All systems initialized successfully")
    }
    
    private func connectSystems() {
        // Connect UI to managers
        uiManager.heroManager = heroManager
        uiManager.combatManager = combatManager
        uiManager.inventoryManager = inventoryManager
        
        // Connect input to systems
        inputManager.sceneManager = sceneManager
        inputManager.combatManager = combatManager
        
        // Connect combat to audio
        combatManager.audioManager = audioManager
        
        // Connect scene to all systems
        sceneManager.heroManager = heroManager
        sceneManager.combatManager = combatManager
        sceneManager.audioManager = audioManager
    }
    
    // MARK: - Game Lifecycle
    
    func startNewGame() {
        print("🎬 Starting new game...")
        
        // Initialize default party
        setupDefaultParty()
        
        // Load main game scene
        transitionToScene(.gameWorld)
        
        gameState = .playing
    }
    
    func loadGame(from saveSlot: Int) {
        print("💾 Loading game from slot \(saveSlot)...")
        
        if let gameData = saveManager.loadGame(slot: saveSlot) {
            restoreGameState(from: gameData)
            gameState = .playing
        } else {
            print("❌ Failed to load game")
            gameState = .error("Load failed")
        }
    }
    
    func saveGame(to saveSlot: Int) {
        print("💾 Saving game to slot \(saveSlot)...")
        
        let gameData = createSaveData()
        saveManager.saveGame(data: gameData, slot: saveSlot)
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        gameState = .paused
        sceneKitRenderer.pauseRendering()
        audioManager.pauseAll()
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        sceneKitRenderer.resumeRendering()
        audioManager.resumeAll()
    }
    
    // MARK: - Scene Management
    
    func transitionToScene(_ sceneType: GameSceneType) {
        print("🎬 Transitioning to scene: \(sceneType)")
        
        currentScene = sceneType
        sceneManager.loadScene(sceneType)
        
        // Update UI for scene
        uiManager.setupUIForScene(sceneType)
    }
    
    // MARK: - Combat System
    
    func startCombat(with enemies: [Enemy]) {
        print("⚔️ Starting combat with \(enemies.count) enemies")
        
        currentEnemies = enemies
        isInCombat = true
        
        combatManager.initializeCombat(heroes: currentParty, enemies: enemies)
        transitionToScene(.combat)
        
        audioManager.playMusic(.combat)
    }
    
    func endCombat(result: CombatResult) {
        print("🏁 Combat ended: \(result)")
        
        isInCombat = false
        currentEnemies.removeAll()
        
        // Handle combat rewards
        processCombatRewards(result)
        
        transitionToScene(.gameWorld)
        audioManager.playMusic(.exploration)
    }
    
    // MARK: - Party Management
    
    private func setupDefaultParty() {
        let mage = Mage(name: "Lysander")
        let warrior = Warrior(name: "Thorin")
        let rogue = Rogue(name: "Shade")
        
        currentParty = [mage, warrior, rogue]
        heroManager.setActiveParty(currentParty)
        
        print("🧙‍♂️ Default party created: \(currentParty.map { $0.name }.joined(separator: ", "))")
    }
    
    // MARK: - Game Loop
    
    func update(deltaTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        // Update core systems
        sceneManager.update(deltaTime: deltaTime)
        combatManager.update(deltaTime: deltaTime)
        audioManager.update(deltaTime: deltaTime)
        
        // Update performance metrics
        updatePerformanceMetrics()
        
        // Process status effects
        for hero in currentParty {
            hero.processStatusEffects()
        }
        
        for enemy in currentEnemies {
            enemy.processStatusEffects()
        }
    }
    
    private func updatePerformanceMetrics() {
        frameRate = sceneKitRenderer.currentFrameRate
        memoryUsage = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
        renderTime = sceneKitRenderer.lastRenderTime
    }
    
    // MARK: - Save/Load System
    
    private func createSaveData() -> GameSaveData {
        return GameSaveData(
            party: currentParty,
            currentScene: currentScene,
            gameSettings: gameSettings,
            timestamp: Date()
        )
    }
    
    private func restoreGameState(from data: GameSaveData) {
        currentParty = data.party
        currentScene = data.currentScene
        gameSettings = data.gameSettings
        
        heroManager.setActiveParty(currentParty)
        transitionToScene(currentScene)
    }
    
    private func processCombatRewards(_ result: CombatResult) {
        switch result {
        case .victory(let enemies):
            // Award XP and loot
            let totalXP = enemies.reduce(0) { $0 + $1.pointValue }
            for hero in currentParty {
                hero.gainExperience(totalXP / currentParty.count)
            }
            
        case .defeat:
            // Handle game over
            gameState = .gameOver
            
        case .fled:
            // Penalty for fleeing
            break
        }
    }
    
    // MARK: - Debug and Development
    
    func getSystemStatus() -> String {
        var status = ["=== GameMaster System Status ==="]
        status.append("Game State: \(gameState)")
        status.append("Current Scene: \(currentScene)")
        status.append("Frame Rate: \(String(format: "%.1f", frameRate)) FPS")
        status.append("Memory Usage: \(String(format: "%.1f", memoryUsage)) MB")
        status.append("Party Size: \(currentParty.count)")
        status.append("In Combat: \(isInCombat)")
        status.append("Assets Loaded: \(assetManager.getAssetsByCategory(.nature).count)")
        
        return status.joined(separator: "\n")
    }
    
    func enableDebugMode() {
        gameSettings.debugMode = true
        sceneKitRenderer.showDebugInfo = true
        print("🔧 Debug mode enabled")
    }
    
    func resetGame() {
        print("🔄 Resetting game state...")
        
        currentParty.removeAll()
        currentEnemies.removeAll()
        isInCombat = false
        
        transitionToScene(.mainMenu)
        gameState = .ready
    }
}

// MARK: - Supporting Types

enum GameState {
    case initializing
    case ready
    case playing
    case paused
    case gameOver
    case error(String)
}

enum GameSceneType {
    case mainMenu
    case gameWorld
    case combat
    case inventory
    case settings
    case credits
}

enum CombatResult {
    case victory([Enemy])
    case defeat
    case fled
}

struct GameSettings {
    var debugMode: Bool = false
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var graphicsQuality: GraphicsQuality = .high
    var difficulty: GameDifficulty = .normal
}

enum GraphicsQuality {
    case low, medium, high, ultra
}

enum GameDifficulty {
    case easy, normal, hard, nightmare
}

struct GameSaveData: Codable {
    let party: [Hero]
    let currentScene: GameSceneType
    let gameSettings: GameSettings
    let timestamp: Date
}

// MARK: - Manager Stub Classes (to be implemented)

class SceneManager {
    private let renderer: SceneKitRenderer
    var heroManager: HeroManager?
    var combatManager: CombatManager?
    var audioManager: AudioManager?
    
    init(renderer: SceneKitRenderer) {
        self.renderer = renderer
    }
    
    func loadScene(_ type: GameSceneType) {
        // Implementation for scene loading
    }
    
    func update(deltaTime: TimeInterval) {
        // Implementation for scene updates
    }
}

class AudioManager {
    func playMusic(_ type: MusicType) {}
    func pauseAll() {}
    func resumeAll() {}
    func update(deltaTime: TimeInterval) {}
}

enum MusicType {
    case menu, exploration, combat, victory
}

class InputManager {
    var sceneManager: SceneManager?
    var combatManager: CombatManager?
}

class HeroManager {
    func setActiveParty(_ party: [Hero]) {}
}

class InventoryManager {}

class SaveManager {
    func saveGame(data: GameSaveData, slot: Int) {}
    func loadGame(slot: Int) -> GameSaveData? { return nil }
}

class SceneKitRenderer {
    var currentFrameRate: Double = 60.0
    var lastRenderTime: Double = 0.0
    var showDebugInfo: Bool = false
    
    func pauseRendering() {}
    func resumeRendering() {}
}