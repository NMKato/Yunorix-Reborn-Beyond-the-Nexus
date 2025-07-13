//
//  CombatSystem.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Combat Manager

@MainActor
class CombatManager: ObservableObject {
    
    // MARK: - Combat State
    
    @Published var isInCombat: Bool = false
    @Published var currentTurn: Int = 0
    @Published var combatLog: [String] = []
    @Published var heroes: [Hero] = []
    @Published var enemies: [Enemy] = []
    @Published var combatResult: CombatResult?
    
    private var turnOrder: [Character] = []
    private var currentCharacterIndex: Int = 0
    
    // Audio manager reference
    weak var audioManager: AudioManager?
    
    init() {
        print("⚔️ CombatManager initialized")
    }
    
    // MARK: - Input Handling
    
    func handleInput(_ inputVector: CGPoint) {
        // Handle combat input (for manual combat control)
        print("🎮 Combat input: \(inputVector)")
    }
    
    // MARK: - Combat Initialization
    
    func initializeCombat(heroes: [Hero], enemies: [Enemy]) {
        startCombat(heroes: heroes, enemies: enemies)
    }
    
    func startCombat(heroes: [Hero], enemies: [Enemy]) {
        self.heroes = heroes.filter { $0.isAlive() }
        self.enemies = enemies.filter { $0.isAlive() }
        
        guard !self.heroes.isEmpty && !self.enemies.isEmpty else {
            print("❌ Kampf kann nicht gestartet werden: Keine lebenden Charaktere!")
            return
        }
        
        isInCombat = true
        currentTurn = 1
        combatLog.removeAll()
        combatResult = nil
        
        setupTurnOrder()
        logMessage("⚔️ === Kampf beginnt! ===")
        logMessage("Helden: \(self.heroes.map { $0.name }.joined(separator: ", "))")
        logMessage("Gegner: \(self.enemies.map { $0.name }.joined(separator: ", "))")
        
        executeCombatTurn()
    }
    
    private func setupTurnOrder() {
        turnOrder.removeAll()
        
        let allCharacters = (heroes as [Character]) + (enemies as [Character])
        let charactersWithInitiative = allCharacters.map { character in
            return (character, character.initiative)
        }
        
        turnOrder = charactersWithInitiative
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
            .filter { $0.isAlive() }
        
        currentCharacterIndex = 0
        
        logMessage("🎯 Initiativfolge: \(turnOrder.map { $0.name }.joined(separator: " → "))")
    }
    
    // MARK: - Turn Management
    
    private func executeCombatTurn() {
        guard isInCombat else { return }
        
        while currentCharacterIndex < turnOrder.count {
            let currentCharacter = turnOrder[currentCharacterIndex]
            
            guard currentCharacter.isAlive() && !currentCharacter.isIncapacitated() else {
                logMessage("⏭️ \(currentCharacter.name) ist handlungsunfähig und verliert den Zug.")
                nextCharacter()
                continue
            }
            
            executeCharacterTurn(currentCharacter)
            break
        }
        
        if currentCharacterIndex >= turnOrder.count {
            endTurn()
        }
    }
    
    private func executeCharacterTurn(_ character: Character) {
        logMessage("\n🎯 \(character.name) ist am Zug!")
        
        if let hero = character as? Hero {
            executeHeroTurn(hero)
        } else if let enemy = character as? Enemy {
            executeEnemyTurn(enemy)
        }
    }
    
    private func executeHeroTurn(_ hero: Hero) {
        let aliveEnemies = enemies.filter { $0.isAlive() }
        guard !aliveEnemies.isEmpty else {
            endCombat(result: .victory)
            return
        }
        
        logMessage("💭 \(hero.name) wählt eine Aktion...")
        
        if let selectedEnemy = selectTargetForHero(hero, availableTargets: aliveEnemies) {
            performHeroAction(hero, target: selectedEnemy)
        }
        
        nextCharacter()
    }
    
    private func executeEnemyTurn(_ enemy: Enemy) {
        let aliveHeroes = heroes.filter { $0.isAlive() }
        guard !aliveHeroes.isEmpty else {
            endCombat(result: .defeat)
            return
        }
        
        enemy.performAITurn(against: aliveHeroes)
        nextCharacter()
    }
    
    private func nextCharacter() {
        currentCharacterIndex += 1
        
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 1_000_000_000)
            executeCombatTurn()
        }
    }
    
    private func endTurn() {
        currentTurn += 1
        logMessage("\n⏰ === Ende von Runde \(currentTurn - 1) ===")
        
        processStatusEffectsForAllCharacters()
        removeDefeatedCharacters()
        
        if checkCombatEnd() {
            return
        }
        
        setupTurnOrder()
        logMessage("\n🔄 === Runde \(currentTurn) beginnt ===")
        executeCombatTurn()
    }
    
    // MARK: - Action Execution
    
    private func selectTargetForHero(_ hero: Hero, availableTargets: [Enemy]) -> Enemy? {
        return availableTargets.randomElement()
    }
    
    private func performHeroAction(_ hero: Hero, target: Enemy) {
        let actionType = selectHeroAction(hero)
        
        switch actionType {
        case .attack(let attackIndex):
            hero.performAttack(on: target, attackIndex: attackIndex)
            
        case .defend:
            hero.defend()
            logMessage("🛡️ \(hero.name) verteidigt sich!")
            
        case .useItem(let itemIndex, _):
            if hero.inventory.getItem(at: itemIndex) != nil {
                hero.inventory.useItem(at: itemIndex, on: hero)
            }
            
        case .special(let abilityIndex):
            performSpecialAbility(hero, abilityIndex: abilityIndex, target: target)
            
        case .flee:
            attemptFlee(hero)
        }
    }
    
    private func selectHeroAction(_ hero: Hero) -> CombatAction {
        if hero.healthPercentage() < 0.3 && hasHealingItems(hero) {
            return .useItem(itemIndex: findHealingItemIndex(hero), targetIndex: nil)
        }
        
        if let mageHero = hero as? Mage, mageHero.hasEnoughMana(25) {
            let spellIndex = Int.random(in: 0..<hero.attacks.count)
            return .special(abilityIndex: spellIndex)
        }
        
        if let warriorHero = hero as? Warrior, warriorHero.rage >= 50 {
            return .special(abilityIndex: 3)
        }
        
        if let rogueHero = hero as? Rogue, !rogueHero.stealth && Double.random(in: 0...1) < 0.3 {
            return .special(abilityIndex: 3)
        }
        
        let attackIndex = Int.random(in: 0..<hero.attacks.count)
        return .attack(attackIndex: attackIndex)
    }
    
    private func performSpecialAbility(_ hero: Hero, abilityIndex: Int, target: Enemy) {
        guard abilityIndex < hero.attacks.count else { return }
        
        let abilityName = hero.attacks[abilityIndex]
        
        if let mage = hero as? Mage {
            mage.performSpecificAttack(abilityName, on: target)
        } else if let warrior = hero as? Warrior {
            warrior.performSpecificAttack(abilityName, on: target)
        } else if let rogue = hero as? Rogue {
            rogue.performSpecificAttack(abilityName, on: target)
        } else {
            hero.performAttack(on: target, attackIndex: abilityIndex)
        }
    }
    
    private func hasHealingItems(_ hero: Hero) -> Bool {
        return !hero.inventory.getItemsByType(.healing).isEmpty
    }
    
    private func findHealingItemIndex(_ hero: Hero) -> Int {
        for i in 0..<hero.inventory.usedSlots {
            if let item = hero.inventory.getItem(at: i), item.itemType == .healing {
                return i
            }
        }
        return 0
    }
    
    private func attemptFlee(_ hero: Hero) -> Bool {
        let fleeChance = 0.7
        let success = Double.random(in: 0...1) < fleeChance
        
        if success {
            logMessage("💨 \(hero.name) flieht erfolgreich aus dem Kampf!")
            heroes.removeAll { $0.name == hero.name }
            
            if heroes.isEmpty {
                endCombat(result: .fled)
            }
            
            return true
        } else {
            logMessage("❌ \(hero.name) kann nicht fliehen!")
            return false
        }
    }
    
    // MARK: - Status Effect Processing
    
    private func processStatusEffectsForAllCharacters() {
        logMessage("\n🔮 Statuseffekte werden verarbeitet...")
        
        let allCharacters = (heroes as [Character]) + (enemies as [Character])
        
        for character in allCharacters where character.isAlive() {
            let oldHP = character.healthPoints
            character.processStatusEffects()
            
            if character.healthPoints != oldHP {
                let change = character.healthPoints - oldHP
                let changeText = change > 0 ? "heilt \(Int(change)) LP" : "verliert \(Int(-change)) LP"
                logMessage("💫 \(character.name) \(changeText) durch Statuseffekte.")
            }
        }
    }
    
    private func removeDefeatedCharacters() {
        let defeatedHeroes = heroes.filter { $0.isDefeated() }
        let defeatedEnemies = enemies.filter { $0.isDefeated() }
        
        for hero in defeatedHeroes {
            logMessage("💀 \(hero.name) wurde besiegt!")
        }
        
        for enemy in defeatedEnemies {
            logMessage("💀 \(enemy.name) wurde besiegt!")
            awardExperienceForDefeat(enemy)
            awardLootForDefeat(enemy)
        }
        
        heroes = heroes.filter { !$0.isDefeated() }
        enemies = enemies.filter { !$0.isDefeated() }
        turnOrder = turnOrder.filter { !$0.isDefeated() }
    }
    
    private func awardExperienceForDefeat(_ enemy: Enemy) {
        let experience = enemy.pointValue / 10
        
        for hero in heroes where hero.isAlive() {
            hero.gainExperience(experience)
            logMessage("⭐ \(hero.name) erhält \(experience) Erfahrungspunkte!")
        }
    }
    
    private func awardLootForDefeat(_ enemy: Enemy) {
        let loot = ItemFactory.createLootForEnemy(enemy)
        
        guard !loot.isEmpty else { return }
        
        logMessage("💎 \(enemy.name) hinterlässt Beute:")
        
        for item in loot {
            let recipient = heroes.filter { $0.isAlive() }.randomElement()
            if let hero = recipient, hero.inventory.addItem(item) {
                logMessage("  📦 \(hero.name) erhält \(item.name)")
            } else {
                logMessage("  ❌ \(item.name) konnte nicht aufgehoben werden (Inventar voll)")
            }
        }
    }
    
    // MARK: - Combat End Conditions
    
    private func checkCombatEnd() -> Bool {
        let aliveHeroes = heroes.filter { $0.isAlive() }
        let aliveEnemies = enemies.filter { $0.isAlive() }
        
        if aliveEnemies.isEmpty {
            endCombat(result: .victory)
            return true
        }
        
        if aliveHeroes.isEmpty {
            endCombat(result: .defeat)
            return true
        }
        
        return false
    }
    
    private func endCombat(result: CombatResult) {
        isInCombat = false
        combatResult = result
        
        switch result {
        case .victory:
            logMessage("\n🎉 === SIEG! ===")
            logMessage("Die Helden haben triumphiert!")
            
        case .defeat:
            logMessage("\n💀 === NIEDERLAGE! ===")
            logMessage("Die Helden wurden besiegt...")
            
        case .fled:
            logMessage("\n💨 === FLUCHT! ===")
            logMessage("Die Helden sind geflohen!")
        }
        
        logMessage("\nKampf beendet nach \(currentTurn) Runden.")
        
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 3_000_000_000)
            resetCombat()
        }
    }
    
    private func resetCombat() {
        turnOrder.removeAll()
        currentCharacterIndex = 0
        currentTurn = 0
        
        for character in (heroes as [Character]) + (enemies as [Character]) {
            character.isDefending = false
            character.removeStatus(.defending)
        }
    }
    
    // MARK: - Utility Methods
    
    private func logMessage(_ message: String) {
        combatLog.append(message)
        print(message)
        
        if combatLog.count > 100 {
            combatLog.removeFirst()
        }
    }
    
    func getCombatStatus() -> String {
        var status = "⚔️ === Kampfstatus ===\n"
        status += "Runde: \(currentTurn)\n"
        status += "Am Zug: \(currentCharacterIndex < turnOrder.count ? turnOrder[currentCharacterIndex].name : "Niemand")\n\n"
        
        status += "🦸 Helden:\n"
        for hero in heroes {
            status += "  \(hero.description)\n"
        }
        
        status += "\n👹 Gegner:\n"
        for enemy in enemies {
            status += "  \(enemy.description)\n"
        }
        
        return status
    }
    
    func getDetailedCombatLog() -> String {
        return combatLog.joined(separator: "\n")
    }
    
    // MARK: - Update Loop
    
    func update(deltaTime: TimeInterval) {
        guard isInCombat else { return }
        
        // Process status effects for all characters
        for character in turnOrder {
            character.processStatusEffects()
        }
        
        // Remove defeated characters (use existing method)
        removeDefeatedCharacters()
        
        // Check if combat should end
        _ = checkCombatEnd()
    }
}

// MARK: - Combat Result

enum CombatResult {
    case victory
    case defeat
    case fled
    
    var description: String {
        switch self {
        case .victory: return "Sieg"
        case .defeat: return "Niederlage"
        case .fled: return "Flucht"
        }
    }
    
    var emoji: String {
        switch self {
        case .victory: return "🎉"
        case .defeat: return "💀"
        case .fled: return "💨"
        }
    }
}

// MARK: - Combat Utilities

extension CombatManager {
    
    func createTestCombat() {
        let testHeroes = [
            Mage(name: "Gandalf"),
            Warrior(name: "Aragorn"),
            Rogue(name: "Legolas")
        ]
        
        let testEnemies = [
            Skeleton(),
            Orc()
        ]
        
        for hero in testHeroes {
            hero.inventory.addItem(ItemFactory.healingItems[0])
            hero.inventory.addItem(ItemFactory.healingItems[1])
        }
        
        startCombat(heroes: testHeroes, enemies: testEnemies)
    }
    
    func createBossFight() {
        let heroes = [
            Mage(name: "Erzmagier"),
            Warrior(name: "Paladin"),
            Rogue(name: "Assassine")
        ]
        
        for hero in heroes {
            hero.level = 5
            hero.maxHealthPoints += 50
            hero.healthPoints = hero.maxHealthPoints
            hero.attackPower += 10
            hero.defenseValue += 5
            
            hero.inventory.addItem(ItemFactory.healingItems[2])
            hero.inventory.addItem(ItemFactory.specialItems[1])
        }
        
        let boss = FinalBoss()
        
        startCombat(heroes: heroes, enemies: [boss])
    }
    
    func simulateQuickCombat() -> CombatResult {
        let hero = Warrior(name: "Held")
        let enemy = Skeleton()
        
        while hero.isAlive() && enemy.isAlive() {
            hero.performAttack(on: enemy, attackIndex: 0)
            
            if enemy.isAlive() {
                enemy.performAttack(on: hero, attackIndex: 0)
            }
        }
        
        return hero.isAlive() ? .victory : .defeat
    }
}