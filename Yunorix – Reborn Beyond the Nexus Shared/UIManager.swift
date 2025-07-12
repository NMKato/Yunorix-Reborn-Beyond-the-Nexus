//
//  UIManager.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

#if os(macOS)
    import AppKit
    typealias PlatformColor = NSColor
#else
    import UIKit
    typealias PlatformColor = UIColor
#endif

// MARK: - Game UI Manager

@MainActor
class UIManager: ObservableObject {
    
    // MARK: - UI State
    
    @Published var showPlayerStats: Bool = true
    @Published var showMiniMap: Bool = true
    @Published var showActionButtons: Bool = true
    @Published var showInventory: Bool = false
    @Published var showSpellBook: Bool = false
    
    // MARK: - Game State References
    
    @Published var currentPlayer: SceneKitHero?
    @Published var selectedTarget: SceneKitCharacter?
    @Published var gameScene: GameScene?
    @Published var playerController: PlayerNode?
    
    // MARK: - Combat UI
    
    @Published var isInCombat: Bool = false
    @Published var combatTargets: [SceneKitCharacter] = []
    @Published var selectedSpell: String? = nil
    
    // MARK: - Messages
    
    @Published var gameMessages: [GameMessage] = []
    @Published var showMessages: Bool = true
    
    // MARK: - Initialization
    
    init() {
        setupInitialMessages()
    }
    
    private func setupInitialMessages() {
        addMessage("🎮 Welcome to Yunorix - Reborn Beyond the Nexus!", type: .system)
        addMessage("⚔️ Use WASD to move, click to select targets", type: .info)
    }
    
    // MARK: - Message System
    
    func addMessage(_ text: String, type: GameMessageType = .info) {
        let message = GameMessage(text: text, type: type, timestamp: Date())
        gameMessages.append(message)
        
        // Keep only last 50 messages
        if gameMessages.count > 50 {
            gameMessages.removeFirst()
        }
    }
    
    func clearMessages() {
        gameMessages.removeAll()
    }
    
    // MARK: - Player Actions
    
    func performPlayerAction(_ action: PlayerUIAction) {
        guard let player = currentPlayer, let controller = playerController else { return }
        
        switch action {
        case .attack:
            if let target = selectedTarget {
                controller.attackTarget(target)
                addMessage("⚔️ \(player.name) attacks \(target.name)!", type: .combat)
            }
            
        case .defend:
            player.defend()
            addMessage("🛡️ \(player.name) defends!", type: .combat)
            
        case .castSpell(let spellName):
            if let target = selectedTarget {
                controller.castSpell(spellName: spellName, target: target)
                addMessage("✨ \(player.name) casts \(spellName)!", type: .magic)
            }
            
        case .useItem(let itemName):
            // Item usage would be implemented here
            addMessage("🎒 \(player.name) uses \(itemName)!", type: .item)
            
        case .move(let direction):
            let currentPos = player.worldPosition
            let newPos = calculateMovementPosition(from: currentPos, direction: direction)
            controller.moveHero(to: newPos)
            
        case .wait:
            addMessage("⏳ \(player.name) waits...", type: .info)
        }
    }
    
    private func calculateMovementPosition(from current: SCNVector3, direction: MovementDirection) -> SCNVector3 {
        let moveDistance: Float = 2.0
        
        switch direction {
        case .north:
            return SCNVector3(current.x, current.y, current.z - moveDistance)
        case .south:
            return SCNVector3(current.x, current.y, current.z + moveDistance)
        case .east:
            return SCNVector3(current.x + moveDistance, current.y, current.z)
        case .west:
            return SCNVector3(current.x - moveDistance, current.y, current.z)
        }
    }
    
    // MARK: - Spell Management
    
    func getAvailableSpells() -> [SpellInfo] {
        guard let mage = currentPlayer as? SceneKitMage else { return [] }
        
        return [
            SpellInfo(name: "Heal", manaCost: 25, description: "Restore health", icon: "❤️"),
            SpellInfo(name: "Fireball", manaCost: 30, description: "Fire damage", icon: "🔥"),
            SpellInfo(name: "Ice Lance", manaCost: 25, description: "Ice damage + slow", icon: "❄️"),
            SpellInfo(name: "Lightning", manaCost: 35, description: "Lightning damage", icon: "⚡"),
            SpellInfo(name: "Meteor", manaCost: 50, description: "Area damage", icon: "💫")
        ].filter { mage.hasEnoughMana($0.manaCost) }
    }
    
    // MARK: - Combat UI Management
    
    func startCombat(with targets: [SceneKitCharacter]) {
        isInCombat = true
        combatTargets = targets
        showActionButtons = true
        addMessage("⚔️ Combat started!", type: .combat)
    }
    
    func endCombat() {
        isInCombat = false
        combatTargets.removeAll()
        selectedTarget = nil
        addMessage("✅ Combat ended!", type: .combat)
    }
    
    // MARK: - Target Selection
    
    func selectTarget(_ target: SceneKitCharacter?) {
        selectedTarget = target
        
        if let target = target {
            addMessage("🎯 Selected: \(target.name)", type: .info)
        }
    }
    
    // MARK: - UI Layout Helper Functions
    
    func getPlayerHealthPercentage() -> Double {
        return currentPlayer?.healthPercentage() ?? 0.0
    }
    
    func getPlayerManaPercentage() -> Double {
        guard let mage = currentPlayer as? SceneKitMage else { return 0.0 }
        return mage.mana / mage.maxMana
    }
    
    func getTargetHealthPercentage() -> Double {
        return selectedTarget?.healthPercentage() ?? 0.0
    }
    
    // MARK: - Settings
    
    func toggleUI(_ component: UIComponent) {
        switch component {
        case .playerStats:
            showPlayerStats.toggle()
        case .miniMap:
            showMiniMap.toggle()
        case .actionButtons:
            showActionButtons.toggle()
        case .inventory:
            showInventory.toggle()
        case .spellBook:
            showSpellBook.toggle()
        case .messages:
            showMessages.toggle()
        }
    }
}

// MARK: - Supporting Types

struct GameMessage: Identifiable {
    let id = UUID()
    let text: String
    let type: GameMessageType
    let timestamp: Date
}

enum GameMessageType {
    case system
    case info
    case combat
    case magic
    case item
    case error
    
    var color: Color {
        switch self {
        case .system: return .blue
        case .info: return .primary
        case .combat: return .red
        case .magic: return .purple
        case .item: return .green
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "🎮"
        case .info: return "ℹ️"
        case .combat: return "⚔️"
        case .magic: return "✨"
        case .item: return "🎒"
        case .error: return "❌"
        }
    }
}

enum PlayerUIAction {
    case attack
    case defend
    case castSpell(String)
    case useItem(String)
    case move(MovementDirection)
    case wait
}

enum MovementDirection {
    case north, south, east, west
}

enum UIComponent {
    case playerStats
    case miniMap
    case actionButtons
    case inventory
    case spellBook
    case messages
}

struct SpellInfo {
    let name: String
    let manaCost: Double
    let description: String
    let icon: String
}

// MARK: - SwiftUI Views

struct PlayerStatsView: View {
    @ObservedObject var uiManager: UIManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let player = uiManager.currentPlayer {
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                // Health Bar
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("HP")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(player.healthPoints))/\(Int(player.maxHealthPoints))")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    
                    ProgressView(value: uiManager.getPlayerHealthPercentage())
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                
                // Mana Bar (for Mage)
                if let mage = player as? SceneKitMage {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("MP")
                                .font(.caption)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(mage.mana))/\(Int(mage.maxMana))")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        
                        ProgressView(value: uiManager.getPlayerManaPercentage())
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
    }
}

struct ActionButtonsView: View {
    @ObservedObject var uiManager: UIManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            Button("⚔️ Attack") {
                uiManager.performPlayerAction(.attack)
            }
            .buttonStyle(GameButtonStyle())
            .disabled(uiManager.selectedTarget == nil)
            
            Button("🛡️ Defend") {
                uiManager.performPlayerAction(.defend)
            }
            .buttonStyle(GameButtonStyle())
            
            Button("✨ Spells") {
                uiManager.showSpellBook.toggle()
            }
            .buttonStyle(GameButtonStyle())
            
            Button("🎒 Items") {
                uiManager.showInventory.toggle()
            }
            .buttonStyle(GameButtonStyle())
            
            Button("⏳ Wait") {
                uiManager.performPlayerAction(.wait)
            }
            .buttonStyle(GameButtonStyle())
            
            Button("🏃 Move") {
                // Show movement options
            }
            .buttonStyle(GameButtonStyle())
        }
        .padding()
    }
}

struct GameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundStyle(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct MessageLogView: View {
    @ObservedObject var uiManager: UIManager
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(uiManager.gameMessages.suffix(10)) { message in
                    HStack {
                        Text(message.type.icon)
                        Text(message.text)
                            .font(.caption)
                            .foregroundStyle(message.type.color)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(height: 120)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .padding()
    }
}