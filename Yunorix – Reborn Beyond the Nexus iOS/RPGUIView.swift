//
//  RPGUIView.swift
//  Yunorix – Reborn Beyond the Nexus iOS
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit
import Foundation

// MARK: - Main RPG UI Container

struct RPGUIView: View {
    @StateObject private var gameController: GameController
    @State private var selectedHero: Hero?
    @State private var showInventory = false
    @State private var showCombatLog = false
    @State private var showCharacterStats = false
    
    init(gameController: GameController) {
        self._gameController = StateObject(wrappedValue: gameController)
    }
    
    var body: some View {
        ZStack {
            // Main game view (SceneKit view would be behind this)
            Color.clear
            
            VStack {
                // Top HUD
                HStack {
                    HeroPartyView(heroes: gameController.getCurrentHeroes(), selectedHero: $selectedHero)
                    Spacer()
                    CombatStatusView(combatManager: gameController.getCombatManager())
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                // Bottom action bar
                ActionBarView(
                    gameController: gameController,
                    selectedHero: $selectedHero,
                    showInventory: $showInventory,
                    showCombatLog: $showCombatLog,
                    showCharacterStats: $showCharacterStats
                )
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showInventory) {
            if let hero = selectedHero {
                InventoryUIView(hero: hero)
            }
        }
        .sheet(isPresented: $showCombatLog) {
            CombatLogView(combatManager: gameController.getCombatManager())
        }
        .sheet(isPresented: $showCharacterStats) {
            if let hero = selectedHero {
                CharacterStatsView(character: hero)
            }
        }
    }
}

// MARK: - Hero Party Display

struct HeroPartyView: View {
    let heroes: [Hero]
    @Binding var selectedHero: Hero?
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(heroes, id: \.name) { hero in
                HeroPortraitView(hero: hero, isSelected: selectedHero?.name == hero.name)
                    .onTapGesture {
                        selectedHero = hero
                    }
            }
        }
    }
}

struct HeroPortraitView: View {
    @ObservedObject var hero: Hero
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Portrait background
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.yellow.opacity(0.3) : Color.black.opacity(0.5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.yellow : Color.gray, lineWidth: 2)
                    )
                
                // Character class icon
                Text(heroClassIcon(for: hero))
                    .font(.title2)
            }
            
            // Health bar
            ProgressView(value: hero.healthPercentage())
                .progressViewStyle(HealthBarStyle())
                .frame(width: 60, height: 4)
            
            // Mana bar (for mages)
            if let mage = hero as? Mage {
                ProgressView(value: mage.mana / mage.maxMana)
                    .progressViewStyle(ManaBarStyle())
                    .frame(width: 60, height: 4)
            }
            
            // Hero name
            Text(hero.name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
    
    private func heroClassIcon(for hero: Hero) -> String {
        if hero is Mage { return "🧙‍♂️" }
        if hero is Warrior { return "⚔️" }
        if hero is Rogue { return "🗡️" }
        return "🦸"
    }
}

// MARK: - Combat Status Display

struct CombatStatusView: View {
    @ObservedObject var combatManager: CombatManager
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if combatManager.isInCombat {
                HStack {
                    Text("⚔️")
                    Text("Runde \(combatManager.currentTurn)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.7))
                .cornerRadius(8)
                
                if !combatManager.enemies.isEmpty {
                    Text("\(combatManager.enemies.filter { $0.isAlive() }.count) Gegner")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                HStack {
                    Text("🕊️")
                    Text("Friedlich")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.7))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Action Bar

struct ActionBarView: View {
    let gameController: GameController
    @Binding var selectedHero: Hero?
    @Binding var showInventory: Bool
    @Binding var showCombatLog: Bool
    @Binding var showCharacterStats: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Combat actions
            if gameController.isInCombat() {
                CombatActionsView(gameController: gameController, selectedHero: $selectedHero)
            } else {
                ExplorationActionsView(gameController: gameController)
            }
            
            Spacer()
            
            // UI toggles
            HStack(spacing: 12) {
                ActionButton(icon: "📦", title: "Inventar") {
                    showInventory = true
                }
                .disabled(selectedHero == nil)
                
                ActionButton(icon: "📊", title: "Stats") {
                    showCharacterStats = true
                }
                .disabled(selectedHero == nil)
                
                ActionButton(icon: "📜", title: "Log") {
                    showCombatLog = true
                }
            }
        }
        .padding(.horizontal)
    }
}

struct CombatActionsView: View {
    let gameController: GameController
    @Binding var selectedHero: Hero?
    
    var body: some View {
        HStack(spacing: 8) {
            ActionButton(icon: "⚔️", title: "Angriff") {
                // Trigger attack for selected hero
            }
            .disabled(selectedHero == nil)
            
            ActionButton(icon: "🛡️", title: "Verteidigung") {
                selectedHero?.defend()
            }
            .disabled(selectedHero == nil)
            
            ActionButton(icon: "💨", title: "Flucht") {
                // Attempt to flee combat
            }
        }
    }
}

struct ExplorationActionsView: View {
    let gameController: GameController
    
    var body: some View {
        HStack(spacing: 8) {
            ActionButton(icon: "⚔️", title: "Kampf") {
                gameController.startRandomEncounter()
            }
            
            ActionButton(icon: "👑", title: "Boss") {
                gameController.startBossFight()
            }
            
            ActionButton(icon: "🏠", title: "Lager") {
                // Rest and restore health/mana
                restParty()
            }
        }
    }
    
    private func restParty() {
        for hero in gameController.getCurrentHeroes() {
            hero.heal(hero.maxHealthPoints)
            
            if let mage = hero as? Mage {
                mage.mana = mage.maxMana
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(Color.blue.opacity(0.7))
            .cornerRadius(8)
        }
    }
}

// MARK: - Progress Bar Styles

struct HealthBarStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.3))
            
            RoundedRectangle(cornerRadius: 2)
                .fill(healthColor(for: configuration.fractionCompleted ?? 0))
                .scaleEffect(x: configuration.fractionCompleted ?? 0, y: 1, anchor: .leading)
        }
    }
    
    private func healthColor(for percentage: Double) -> Color {
        if percentage > 0.6 { return .green }
        if percentage > 0.3 { return .yellow }
        return .red
    }
}

struct ManaBarStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.3))
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)
                .scaleEffect(x: configuration.fractionCompleted ?? 0, y: 1, anchor: .leading)
        }
    }
}

// MARK: - Inventory UI

struct InventoryUIView: View {
    @ObservedObject var hero: Hero
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Inventory header
                HStack {
                    Text("📦 \(hero.name)s Inventar")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("\(hero.inventory.usedSlots)/\(hero.inventory.maxCapacity)")
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Items grid
                if hero.inventory.isEmpty {
                    Spacer()
                    Text("Inventar ist leer")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(0..<hero.inventory.usedSlots, id: \.self) { index in
                                if let item = hero.inventory.getItem(at: index) {
                                    ItemView(item: item, hero: hero, index: index)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ItemView: View {
    let item: Item
    @ObservedObject var hero: Hero
    let index: Int
    @State private var showingUseConfirmation = false
    
    var body: some View {
        VStack {
            // Item icon and rarity
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rarityColor(for: item.rarity))
                    .frame(width: 60, height: 60)
                
                Text(item.itemType.emoji)
                    .font(.title2)
            }
            
            Text(item.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Usage count
            if item.isConsumable {
                Text("\(item.maxUsage - item.usageCount)/\(item.maxUsage)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            showingUseConfirmation = true
        }
        .alert("Item verwenden", isPresented: $showingUseConfirmation) {
            Button("Verwenden") {
                _ = hero.inventory.useItem(at: index, on: hero)
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text(item.itemDescription)
        }
    }
    
    private func rarityColor(for rarity: ItemRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Combat Log

struct CombatLogView: View {
    @ObservedObject var combatManager: CombatManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(combatManager.combatLog.indices, id: \.self) { index in
                        Text(combatManager.combatLog[index])
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Kampf-Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Character Stats

struct CharacterStatsView: View {
    @ObservedObject var character: Character
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic stats
                    StatsSection(title: "Grundwerte") {
                        StatRow(label: "Gesundheit", value: "\(Int(character.healthPoints))/\(Int(character.maxHealthPoints))")
                        StatRow(label: "Angriff", value: "\(Int(character.attackPower))")
                        StatRow(label: "Verteidigung", value: "\(Int(character.defenseValue))")
                        StatRow(label: "Kritische Chance", value: "\(Int(character.criticalChance * 100))%")
                    }
                    
                    // Hero-specific stats
                    if let hero = character as? Hero {
                        StatsSection(title: "Held") {
                            StatRow(label: "Level", value: "\(hero.level)")
                            StatRow(label: "Erfahrung", value: "\(hero.experience)")
                        }
                        
                        if let mage = hero as? Mage {
                            StatsSection(title: "Magier") {
                                StatRow(label: "Mana", value: "\(Int(mage.mana))/\(Int(mage.maxMana))")
                                StatRow(label: "Zauberkraft", value: "\(Int(mage.spellPower))")
                            }
                        }
                        
                        if let warrior = hero as? Warrior {
                            StatsSection(title: "Krieger") {
                                StatRow(label: "Schild", value: "\(Int(warrior.shield))/\(Int(warrior.maxShield))")
                                StatRow(label: "Wut", value: "\(Int(warrior.rage))/\(Int(warrior.maxRage))")
                            }
                        }
                        
                        if let rogue = hero as? Rogue {
                            StatsSection(title: "Schurke") {
                                StatRow(label: "Beweglichkeit", value: "\(Int(rogue.agility))")
                                StatRow(label: "Versteckt", value: rogue.stealth ? "Ja" : "Nein")
                            }
                        }
                    }
                    
                    // Status effects
                    if !character.activeStatusEffects.isEmpty {
                        StatsSection(title: "Statuseffekte") {
                            ForEach(character.activeStatusEffects.indices, id: \.self) { index in
                                let effect = character.activeStatusEffects[index]
                                StatRow(
                                    label: effect.effect.description,
                                    value: effect.duration == -1 ? "∞" : "\(effect.duration)"
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(character.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}