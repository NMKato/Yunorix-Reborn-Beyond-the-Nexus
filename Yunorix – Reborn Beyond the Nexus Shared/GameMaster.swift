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
    
    @Published var gameState: GameSystemState = .initializing
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
    var sceneKitRenderer: SceneKitRenderer!
    
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
        memoryUsage = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
        renderTime = sceneKitRenderer.lastRenderTime
    }
    
    // MARK: - Save/Load System
    
    private func createSaveData() -> GameSaveData {
        return GameSaveData(
            partyCount: currentParty.count,
            currentScene: currentScene,
            gameSettings: gameSettings,
            timestamp: Date()
        )
    }
    
    private func restoreGameState(from data: GameSaveData) {
        // Simplified restoration - recreate default party for now
        setupDefaultParty()
        currentScene = data.currentScene
        gameSettings = data.gameSettings
        
        heroManager.setActiveParty(currentParty)
        transitionToScene(currentScene)
    }
    
    private func processCombatRewards(_ result: CombatResult) {
        switch result {
        case .victory:
            // Award XP and loot based on current enemies
            let totalXP = currentEnemies.reduce(0) { $0 + $1.pointValue }
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

enum GameSystemState: Equatable {
    case initializing
    case ready
    case playing
    case paused
    case gameOver
    case error(String)
}

enum GameSceneType: String, Codable {
    case mainMenu = "mainMenu"
    case gameWorld = "gameWorld"
    case combat = "combat"
    case inventory = "inventory"
    case settings = "settings"
    case credits = "credits"
    
    var displayName: String {
        switch self {
        case .mainMenu: return "Main Menu"
        case .gameWorld: return "Open World"
        case .combat: return "Combat"
        case .inventory: return "Inventory"
        case .settings: return "Settings"
        case .credits: return "Credits"
        }
    }
}

// CombatResult is defined in CombatSystem.swift

struct GameSettings: Codable {
    var debugMode: Bool = false
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var graphicsQuality: GraphicsQuality = .high
    var difficulty: GameDifficulty = .normal
}

enum GraphicsQuality: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium" 
    case high = "high"
    case ultra = "ultra"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .ultra: return "Ultra"
        }
    }
}

enum GameDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case normal = "normal"
    case hard = "hard"
    case nightmare = "nightmare"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        case .nightmare: return "Nightmare"
        }
    }
}

struct GameSaveData: Codable {
    let partyCount: Int // Simplified for now instead of [Hero] 
    let currentScene: GameSceneType
    let gameSettings: GameSettings
    let timestamp: Date
}

// MARK: - Manager Implementations

@MainActor
class SceneManager: ObservableObject {
    private let renderer: SceneKitRenderer
    var heroManager: HeroManager?
    var combatManager: CombatManager?
    var audioManager: AudioManager?
    
    @Published var currentSceneType: GameSceneType = .mainMenu
    @Published var isLoading = false
    
    init(renderer: SceneKitRenderer) {
        self.renderer = renderer
        print("📋 SceneManager initialized")
    }
    
    func loadScene(_ type: GameSceneType) {
        print("🎬 Loading scene: \(type)")
        isLoading = true
        currentSceneType = type
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            print("✅ Scene loaded: \(type)")
        }
    }
    
    func update(deltaTime: TimeInterval) {
        // Update scene-specific logic
        switch currentSceneType {
        case .gameWorld:
            updateGameWorld(deltaTime: deltaTime)
        case .combat:
            updateCombat(deltaTime: deltaTime)
        default:
            break
        }
    }
    
    private func updateGameWorld(deltaTime: TimeInterval) {
        // Update world entities, physics, etc.
    }
    
    private func updateCombat(deltaTime: TimeInterval) {
        combatManager?.update(deltaTime: deltaTime)
    }
}

@MainActor
class AudioManager: ObservableObject {
    @Published var currentMusic: MusicType?
    @Published var musicVolume: Float = 0.7
    @Published var effectsVolume: Float = 0.8
    @Published var isMuted = false
    
    private var isPlaying = false
    
    init() {
        print("🎵 AudioManager initialized")
    }
    
    func playMusic(_ type: MusicType) {
        guard !isMuted else { return }
        
        currentMusic = type
        isPlaying = true
        print("🎵 Playing music: \(type)")
        
        // TODO: Implement actual audio playback
    }
    
    func playSound(_ soundName: String, volume: Float = 1.0) {
        guard !isMuted else { return }
        print("🔊 Playing sound: \(soundName)")
        
        // TODO: Implement sound effect playback
    }
    
    func pauseAll() {
        isPlaying = false
        print("⏸️ Audio paused")
    }
    
    func resumeAll() {
        if currentMusic != nil {
            isPlaying = true
            print("▶️ Audio resumed")
        }
    }
    
    func stopAll() {
        isPlaying = false
        currentMusic = nil
        print("⏹️ All audio stopped")
    }
    
    func update(deltaTime: TimeInterval) {
        // Update audio system (fade in/out, etc.)
    }
    
    func setMasterVolume(_ volume: Float) {
        musicVolume = volume
        effectsVolume = volume
    }
}

enum MusicType: String, CaseIterable {
    case menu = "menu"
    case exploration = "exploration"
    case combat = "combat"
    case victory = "victory"
    case ambient = "ambient"
    
    var displayName: String {
        switch self {
        case .menu: return "Main Menu"
        case .exploration: return "Exploration"
        case .combat: return "Combat"
        case .victory: return "Victory"
        case .ambient: return "Ambient"
        }
    }
}

@MainActor
class InputManager: ObservableObject {
    var sceneManager: SceneManager?
    var combatManager: CombatManager?
    
    @Published var currentInputMode: InputMode = .exploration
    @Published var keyboardEnabled = true
    @Published var touchEnabled = true
    
    // Input state
    private var currentKeys: Set<String> = []
    private var mousePosition = CGPoint.zero
    private var touchPosition = CGPoint.zero
    
    init() {
        print("🎮 InputManager initialized")
    }
    
    func handleKeyDown(_ key: String) {
        guard keyboardEnabled else { return }
        currentKeys.insert(key.lowercased())
        processKeyboardInput()
    }
    
    func handleKeyUp(_ key: String) {
        currentKeys.remove(key.lowercased())
    }
    
    func handleTouch(at position: CGPoint, phase: TouchPhase) {
        guard touchEnabled else { return }
        touchPosition = position
        processTouchInput(phase: phase)
    }
    
    private func processKeyboardInput() {
        var inputVector = CGPoint.zero
        
        if currentKeys.contains("w") { inputVector.y += 1 }
        if currentKeys.contains("s") { inputVector.y -= 1 }
        if currentKeys.contains("a") { inputVector.x -= 1 }
        if currentKeys.contains("d") { inputVector.x += 1 }
        
        // Send to appropriate system
        switch currentInputMode {
        case .exploration:
            NotificationCenter.default.post(name: .playerMovement, object: inputVector)
        case .combat:
            combatManager?.handleInput(inputVector)
        case .menu:
            break
        }
    }
    
    private func processTouchInput(phase: TouchPhase) {
        switch phase {
        case .began:
            NotificationCenter.default.post(name: .touchBegan, object: touchPosition)
        case .moved:
            NotificationCenter.default.post(name: .touchMoved, object: touchPosition)
        case .ended:
            NotificationCenter.default.post(name: .touchEnded, object: touchPosition)
        }
    }
    
    func setInputMode(_ mode: InputMode) {
        currentInputMode = mode
        print("🎮 Input mode changed to: \(mode)")
    }
}

enum InputMode {
    case exploration, combat, menu
}

enum TouchPhase {
    case began, moved, ended
}

extension Notification.Name {
    static let playerMovement = Notification.Name("PlayerMovement")
    static let touchBegan = Notification.Name("TouchBegan")
    static let touchMoved = Notification.Name("TouchMoved")
    static let touchEnded = Notification.Name("TouchEnded")
}

@MainActor
class HeroManager: ObservableObject {
    @Published var activeParty: [Hero] = []
    @Published var selectedHero: Hero?
    @Published var partyExperience: Int = 0
    
    private let maxPartySize = 4
    
    init() {
        print("⚔️ HeroManager initialized")
    }
    
    func setActiveParty(_ party: [Hero]) {
        activeParty = Array(party.prefix(maxPartySize))
        selectedHero = activeParty.first
        print("👥 Active party set: \(activeParty.count) heroes")
        
        for hero in activeParty {
            print("  - \(hero.name) (Level \(hero.level), HP: \(hero.currentHealth)/\(hero.maxHealth))")
        }
    }
    
    func addHero(_ hero: Hero) -> Bool {
        guard activeParty.count < maxPartySize else {
            print("❌ Party is full!")
            return false
        }
        
        activeParty.append(hero)
        if selectedHero == nil {
            selectedHero = hero
        }
        
        print("✅ Added \(hero.name) to party")
        return true
    }
    
    func removeHero(_ hero: Hero) {
        if let index = activeParty.firstIndex(where: { $0.id == hero.id }) {
            activeParty.remove(at: index)
            
            if selectedHero?.id == hero.id {
                selectedHero = activeParty.first
            }
            
            print("➖ Removed \(hero.name) from party")
        }
    }
    
    func selectHero(_ hero: Hero) {
        if activeParty.contains(where: { $0.id == hero.id }) {
            selectedHero = hero
            print("👤 Selected hero: \(hero.name)")
        }
    }
    
    func healAllHeroes(_ amount: Int) {
        for hero in activeParty {
            hero.heal(amount)
        }
        print("💚 Healed all heroes for \(amount) HP")
    }
    
    func restoreAllMana(_ amount: Int) {
        for hero in activeParty {
            hero.restoreMana(amount)
        }
        print("💙 Restored all heroes' mana by \(amount)")
    }
    
    func gainPartyExperience(_ amount: Int) {
        partyExperience += amount
        let expPerHero = amount / max(1, activeParty.count)
        
        for hero in activeParty {
            hero.gainExperience(expPerHero)
        }
        
        print("⭐ Party gained \(amount) experience (\(expPerHero) per hero)")
    }
    
    var isPartyAlive: Bool {
        return activeParty.contains { $0.isAlive() }
    }
    
    var totalPartyHealth: Int {
        return activeParty.reduce(0) { $0 + Int($1.currentHealth) }
    }
    
    var totalPartyMana: Int {
        return activeParty.reduce(0) { $0 + Int($1.currentMana) }
    }
}

@MainActor
class InventoryManager: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var capacity: Int = 50
    @Published var currency: Int = 100
    
    init() {
        print("🎒 InventoryManager initialized")
        initializeStartingItems()
    }
    
    private func initializeStartingItems() {
        // Add some starting items
        let healthPotion = ItemFactory.healingItems.first(where: { $0.name == "Heiltrank" }) ?? ItemFactory.healingItems[0]
        let manaPotion = ItemFactory.healingItems.first(where: { $0.name == "Mana-Trank" }) ?? ItemFactory.healingItems[0]
        addItem(healthPotion, quantity: 3)
        addItem(manaPotion, quantity: 2)
        print("🎒 Starting inventory populated")
    }
    
    func addItem(_ item: Item, quantity: Int = 1) -> Bool {
        let totalItems = items.reduce(0) { $0 + $1.quantity }
        
        guard totalItems + quantity <= capacity else {
            print("❌ Inventory is full!")
            return false
        }
        
        // Check if item already exists
        if let existingIndex = items.firstIndex(where: { $0.item.id == item.id }) {
            items[existingIndex].quantity += quantity
        } else {
            items.append(InventoryItem(item: item, quantity: quantity))
        }
        
        print("✅ Added \(quantity)x \(item.name) to inventory")
        return true
    }
    
    func removeItem(_ item: Item, quantity: Int = 1) -> Bool {
        guard let index = items.firstIndex(where: { $0.item.id == item.id }) else {
            print("❌ Item not found in inventory")
            return false
        }
        
        if items[index].quantity <= quantity {
            items.remove(at: index)
        } else {
            items[index].quantity -= quantity
        }
        
        print("➖ Removed \(quantity)x \(item.name) from inventory")
        return true
    }
    
    func useItem(_ item: Item, on target: Hero) -> Bool {
        guard removeItem(item, quantity: 1) else { return false }
        
        var mutableItem = item
        mutableItem.use(on: target)
        print("🔄 Used \(item.name) on \(target.name)")
        return true
    }
    
    func hasItem(_ item: Item, quantity: Int = 1) -> Bool {
        return items.first(where: { $0.item.id == item.id })?.quantity ?? 0 >= quantity
    }
    
    func getItemCount(_ item: Item) -> Int {
        return items.first(where: { $0.item.id == item.id })?.quantity ?? 0
    }
    
    var isFull: Bool {
        let totalItems = items.reduce(0) { $0 + $1.quantity }
        return totalItems >= capacity
    }
    
    var usedSlots: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
    
    var availableSlots: Int {
        return capacity - usedSlots
    }
}

struct InventoryItem: Identifiable {
    let id = UUID()
    let item: Item
    var quantity: Int
}

@MainActor
class SaveManager: ObservableObject {
    private let saveDirectory: URL
    
    @Published var saveSlots: [SaveSlot] = []
    @Published var isLoading = false
    @Published var isSaving = false
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        saveDirectory = documentsPath.appendingPathComponent("YunorixSaves")
        
        createSaveDirectory()
        loadSaveSlots()
        print("💾 SaveManager initialized")
    }
    
    private func createSaveDirectory() {
        try? FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
    }
    
    func saveGame(data: GameSaveData, slot: Int) {
        isSaving = true
        
        let saveURL = saveDirectory.appendingPathComponent("save_\(slot).json")
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            try jsonData.write(to: saveURL)
            
            updateSaveSlot(slot: slot, data: data)
            print("💾 Game saved to slot \(slot)")
        } catch {
            print("❌ Failed to save game: \(error)")
        }
        
        isSaving = false
    }
    
    func loadGame(slot: Int) -> GameSaveData? {
        isLoading = true
        defer { isLoading = false }
        
        let saveURL = saveDirectory.appendingPathComponent("save_\(slot).json")
        
        do {
            let jsonData = try Data(contentsOf: saveURL)
            let gameData = try JSONDecoder().decode(GameSaveData.self, from: jsonData)
            
            print("💾 Game loaded from slot \(slot)")
            return gameData
        } catch {
            print("❌ Failed to load game: \(error)")
            return nil
        }
    }
    
    func deleteSave(slot: Int) {
        let saveURL = saveDirectory.appendingPathComponent("save_\(slot).json")
        
        try? FileManager.default.removeItem(at: saveURL)
        
        if let index = saveSlots.firstIndex(where: { $0.slot == slot }) {
            saveSlots.remove(at: index)
        }
        
        print("🗑️ Save slot \(slot) deleted")
    }
    
    private func loadSaveSlots() {
        saveSlots.removeAll()
        
        for slot in 1...5 {
            let saveURL = saveDirectory.appendingPathComponent("save_\(slot).json")
            
            if FileManager.default.fileExists(atPath: saveURL.path) {
                do {
                    let jsonData = try Data(contentsOf: saveURL)
                    let gameData = try JSONDecoder().decode(GameSaveData.self, from: jsonData)
                    
                    let saveSlot = SaveSlot(
                        slot: slot,
                        timestamp: gameData.timestamp,
                        partyLevel: gameData.party.first?.level ?? 1,
                        playtime: "0:00", // TODO: Track playtime
                        location: gameData.currentScene.rawValue
                    )
                    
                    saveSlots.append(saveSlot)
                } catch {
                    print("❌ Failed to load save slot \(slot): \(error)")
                }
            }
        }
        
        saveSlots.sort { $0.slot < $1.slot }
    }
    
    private func updateSaveSlot(slot: Int, data: GameSaveData) {
        if let index = saveSlots.firstIndex(where: { $0.slot == slot }) {
            saveSlots[index] = SaveSlot(
                slot: slot,
                timestamp: data.timestamp,
                partyLevel: 1, // Simplified
                playtime: "0:00", // TODO: Track playtime
                location: data.currentScene.rawValue
            )
        } else {
            let newSlot = SaveSlot(
                slot: slot,
                timestamp: data.timestamp,
                partyLevel: 1, // Simplified
                playtime: "0:00",
                location: data.currentScene.rawValue
            )
            saveSlots.append(newSlot)
            saveSlots.sort { $0.slot < $1.slot }
        }
    }
    
    func hasSave(slot: Int) -> Bool {
        return saveSlots.contains { $0.slot == slot }
    }
}

struct SaveSlot: Identifiable {
    let id = UUID()
    let slot: Int
    let timestamp: Date
    let partyLevel: Int
    let playtime: String
    let location: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

@MainActor
class SceneKitRenderer: ObservableObject {
    @Published var currentFrameRate: Double = 60.0
    @Published var lastRenderTime: Double = 0.0
    @Published var showDebugInfo: Bool = false
    @Published var isRendering: Bool = true
    
    private var frameCount: Int = 0
    private var lastTime: TimeInterval = 0
    
    init() {
        print("🎨 SceneKitRenderer initialized")
    }
    
    func pauseRendering() {
        isRendering = false
        print("⏸️ Rendering paused")
    }
    
    func resumeRendering() {
        isRendering = true
        print("▶️ Rendering resumed")
    }
    
    func updateMetrics(deltaTime: TimeInterval) {
        guard isRendering else { return }
        
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastTime >= 1.0 {
            currentFrameRate = Double(frameCount) / (currentTime - lastTime)
            frameCount = 0
            lastTime = currentTime
        }
        
        lastRenderTime = deltaTime
    }
    
    func setQuality(_ quality: GraphicsQuality) {
        print("🎨 Graphics quality set to: \(quality.displayName)")
        // TODO: Apply quality settings
    }
    
    func toggleDebugInfo() {
        showDebugInfo.toggle()
        print("🔧 Debug info: \(showDebugInfo ? "ON" : "OFF")")
    }
}