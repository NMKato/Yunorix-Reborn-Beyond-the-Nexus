//
//  Heroes.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Base Hero Class

class Hero: Character, Attackable, PlayerControlled {
    
    // MARK: - Hero Properties
    
    var attacks: [String] = []
    var inventory: Inventory
    var experience: Int = 0
    var level: Int = 1
    
    // MARK: - Initialization
    
    override init(name: String, maxHP: Double, attack: Double, defense: Double) {
        self.inventory = Inventory(maxCapacity: 10)
        super.init(name: name, maxHP: maxHP, attack: attack, defense: defense)
    }
    
    // MARK: - Player Control Methods
    
    func showActionMenu() {
        print("\n=== Aktions-Menü für \(name) ===")
        print("1. Angriff")
        print("2. Verteidigung")
        print("3. Inventar")
        print("4. Status")
        print("5. Flucht")
    }
    
    func processPlayerInput(_ input: String) -> Bool {
        switch input.lowercased() {
        case "1", "angriff", "attack":
            return true
        case "2", "verteidigung", "defend":
            defend()
            return true
        case "3", "inventar", "inventory":
            inventory.showMenu(for: self)
            return false
        case "4", "status":
            print(displayDetailedStatus())
            return false
        case "5", "flucht", "flee":
            print("\(name) versucht zu fliehen!")
            return true
        default:
            print("Ungültige Eingabe. Bitte wähle 1-5.")
            return false
        }
    }
    
    func performPlayerTurn(against availableTargets: [Character]) {
        print("\n\(name) ist am Zug!")
        showActionMenu()
    }
    
    // MARK: - Attack Methods
    
    func performAttack(on target: Character, attackIndex: Int?) {
        guard !isIncapacitated() else {
            print("\(name) kann nicht angreifen!")
            return
        }
        
        let selectedAttack = attackIndex ?? 0
        guard selectedAttack < attacks.count else { return }
        
        let attackName = attacks[selectedAttack]
        performSpecificAttack(attackName, on: target)
    }
    
    func showAttackMenu() {
        print("\n=== Angriffs-Menü für \(name) ===")
        for (index, attack) in attacks.enumerated() {
            print("\(index + 1). \(attack)")
        }
    }
    
    func performSpecificAttack(_ attackName: String, on target: Character) {
        let damage = attackPower
        attack(target: target, damage: damage)
        print("\(name) greift \(target.name) mit \(attackName) an!")
    }
    
    // MARK: - Experience and Leveling
    
    override func gainExperience(_ amount: Int) {
        experience += amount
        checkLevelUp()
    }
    
    private func checkLevelUp() {
        let requiredXP = level * 100
        if experience >= requiredXP {
            levelUp()
        }
    }
    
    private func levelUp() {
        level += 1
        let healthIncrease = maxHealthPoints * 0.1
        maxHealthPoints += healthIncrease
        healthPoints += healthIncrease
        attackPower += 2
        defenseValue += 1
        
        print("\n🌟 \(name) erreicht Level \(level)!")
        print("Gesundheit +\(Int(healthIncrease)), Angriff +2, Verteidigung +1")
    }
}

// MARK: - Mage Class

@MainActor
class Mage: Hero, ManaUser, Healable, AreaAttacker, StatusEffectCaster {
    
    // MARK: - Mage Properties
    
    var spellPower: Double
    var magicalResistance: Double = 0.3
    var availableStatusEffects: [CharacterStatus] = [.cursed, .paralyzed]
    
    // MARK: - ManaUser Protocol Compliance
    // Uses inherited mana property from Character
    
    // MARK: - Initialization
    
    init(name: String) {
        self.spellPower = 15
        
        super.init(name: name, maxHP: 80, attack: 12, defense: 5)
        
        // Set mana after super.init
        self.maxManaPoints = 100
        self.manaPoints = 100
        
        self.attacks = ["Feuerball", "Eisattacke", "Donnerschlag", "Meteor"]
        criticalChance = 0.15
    }
    
    // MARK: - Mana Management
    
    func consumeMana(_ amount: Double) -> Bool {
        guard currentMana >= amount else { return false }
        currentMana -= amount
        return true
    }
    
    func regenerateMana(_ amount: Double) {
        currentMana = min(currentMana + amount, maxMana)
    }
    
    func hasEnoughMana(_ requiredMana: Double) -> Bool {
        return currentMana >= requiredMana
    }
    
    override func processStatusEffects() {
        super.processStatusEffects()
        regenerateMana(10)
    }
    
    // MARK: - Spell Attacks
    
    override func performSpecificAttack(_ attackName: String, on target: Character) {
        switch attackName {
        case "Feuerball":
            castFireball(on: target)
        case "Eisattacke":
            castIceAttack(on: target)
        case "Donnerschlag":
            castLightningStrike(on: target)
        case "Meteor":
            castMeteor(on: [target])
        default:
            super.performSpecificAttack(attackName, on: target)
        }
    }
    
    private func castFireball(on target: Character) {
        guard consumeMana(15) else {
            print("\(name) hat nicht genug Mana für Feuerball!")
            return
        }
        
        let damage = spellPower + attackPower
        attack(target: target, damage: damage, attackType: .fire)
        print("🔥 \(name) schleudert einen Feuerball auf \(target.name)!")
    }
    
    private func castIceAttack(on target: Character) {
        guard consumeMana(20) else {
            print("\(name) hat nicht genug Mana für Eisattacke!")
            return
        }
        
        let damage = spellPower * 1.2
        attack(target: target, damage: damage, attackType: .ice)
        print("❄️ \(name) greift \(target.name) mit Eis an!")
    }
    
    private func castLightningStrike(on target: Character) {
        guard consumeMana(25) else {
            print("\(name) hat nicht genug Mana für Donnerschlag!")
            return
        }
        
        let damage = spellPower * 1.5
        attack(target: target, damage: damage, attackType: .lightning)
        print("⚡ \(name) trifft \(target.name) mit einem Donnerschlag!")
    }
    
    private func castMeteor(on targets: [Character]) {
        guard consumeMana(40) else {
            print("\(name) hat nicht genug Mana für Meteor!")
            return
        }
        
        let damage = spellPower * 2.0
        areaAttack(targets: targets, damage: damage)
        print("💫 \(name) beschwört einen Meteor!")
    }
    
    // MARK: - Area Attack Implementation
    
    func areaAttack(targets: [Character], damage: Double) {
        let reducedDamage = damage * 0.8
        for target in targets where target.isAlive() {
            attack(target: target, damage: reducedDamage, attackType: .magical)
        }
    }
    
    // MARK: - Healing Implementation
    
    func heal(target: Character, amount: Double) {
        let manaCost = amount * 0.5
        guard consumeMana(manaCost) else {
            print("\(name) hat nicht genug Mana zum Heilen!")
            return
        }
        
        target.heal(amount)
        print("✨ \(name) heilt \(target.name) um \(Int(amount)) Lebenspunkte!")
    }
    
    func canHeal(target: Character) -> Bool {
        return !target.isDefeated() && hasEnoughMana(25)
    }
    
    // MARK: - Status Effect Casting
    
    func applyStatusEffect(_ effect: CharacterStatus, to target: Character, duration: Int?) {
        guard availableStatusEffects.contains(effect) else { return }
        
        let manaCost: Double = effect == .cursed ? 30 : 25
        guard consumeMana(manaCost) else {
            print("\(name) hat nicht genug Mana für \(effect.description)!")
            return
        }
        
        target.applyStatus(effect, duration: duration ?? 3)
        print("🔮 \(name) belegt \(target.name) mit \(effect.description)!")
    }
    
    // MARK: - Damage Reduction
    
    override func calculateReducedDamage(_ incomingDamage: Double) -> Double {
        let magicalReduction = incomingDamage * magicalResistance
        let physicalDamage = incomingDamage - magicalReduction
        return super.calculateReducedDamage(physicalDamage)
    }
}

// MARK: - Warrior Class

@MainActor
class Warrior: Hero, StatusResistant, Defendable {
    
    // MARK: - Warrior Properties
    
    @Published var shield: Double
    @Published var maxShield: Double
    @Published var rage: Double = 0
    @Published var maxRage: Double = 100
    var isRaging: Bool = false
    var resistances: [CharacterStatus] = [.paralyzed, .cursed]
    
    // MARK: - Initialization
    
    init(name: String) {
        self.maxShield = 30
        self.shield = 30
        
        super.init(name: name, maxHP: 120, attack: 18, defense: 12)
        
        self.attacks = ["Schwerthieb", "Schildschlag", "Wirbelwind", "Berserker-Wut"]
        criticalChance = 0.12
    }
    
    // MARK: - Shield Management
    
    override func takeDamage(_ amount: Double) {
        if shield > 0 {
            let shieldDamage = min(shield, amount)
            shield -= shieldDamage
            let remainingDamage = amount - shieldDamage
            
            if remainingDamage > 0 {
                super.takeDamage(remainingDamage)
            }
        } else {
            super.takeDamage(amount)
        }
        
        buildRage(amount * 0.3)
    }
    
    override func processStatusEffects() {
        super.processStatusEffects()
        regenerateShield()
        
        if isRaging && !hasStatus(.berserkerRage) {
            isRaging = false
        }
    }
    
    private func regenerateShield() {
        shield = min(shield + maxShield * 0.1, maxShield)
    }
    
    // MARK: - Rage System
    
    private func buildRage(_ amount: Double) {
        rage = min(rage + amount, maxRage)
    }
    
    private func canUseRage() -> Bool {
        return rage >= 50
    }
    
    private func activateBerserkerRage() {
        guard canUseRage() else {
            print("\(name) hat nicht genug Wut für Berserker-Wut!")
            return
        }
        
        rage = 0
        isRaging = true
        applyStatus(.berserkerRage, duration: 5)
        attackPower *= 1.5
        defenseValue *= 0.7
        
        print("🔥 \(name) verfällt in Berserker-Wut!")
    }
    
    // MARK: - Warrior Attacks
    
    override func performSpecificAttack(_ attackName: String, on target: Character) {
        buildRage(5)
        
        switch attackName {
        case "Schwerthieb":
            performSwordStrike(on: target)
        case "Schildschlag":
            performShieldBash(on: target)
        case "Wirbelwind":
            performWhirlwind(on: target)
        case "Berserker-Wut":
            activateBerserkerRage()
        default:
            super.performSpecificAttack(attackName, on: target)
        }
    }
    
    private func performSwordStrike(on target: Character) {
        let damage = attackPower * 1.2
        attack(target: target, damage: damage, attackType: .physical)
        print("⚔️ \(name) führt einen mächtigen Schwerthieb gegen \(target.name) aus!")
    }
    
    private func performShieldBash(on target: Character) {
        let damage = attackPower * 0.9
        attack(target: target, damage: damage, attackType: .physical)
        
        if Double.random(in: 0...1) < 0.4 {
            target.applyStatus(.paralyzed, duration: 1)
            print("🛡️ \(name) betäubt \(target.name) mit einem Schildschlag!")
        } else {
            print("🛡️ \(name) schlägt \(target.name) mit dem Schild!")
        }
    }
    
    private func performWhirlwind(on target: Character) {
        let damage = attackPower * 1.1
        attack(target: target, damage: damage, attackType: .physical)
        print("🌀 \(name) wirbelt herum und trifft \(target.name)!")
    }
    
    // MARK: - Enhanced Defense
    
    override func defend() {
        super.defend()
        shield = min(shield + maxShield * 0.2, maxShield)
        print("🛡️ \(name) verstärkt die Verteidigung und regeneriert das Schild!")
    }
}

// MARK: - Rogue Class

@MainActor
class Rogue: Hero, StatusEffectCaster {
    
    // MARK: - Rogue Properties
    
    @Published var stealth: Bool = false
    @Published var stealthDuration: Int = 0
    @Published var poisonStacks: Int = 0
    var agility: Double
    var availableStatusEffects: [CharacterStatus] = [.poisoned, .paralyzed]
    
    // MARK: - Initialization
    
    init(name: String) {
        self.agility = 18
        
        super.init(name: name, maxHP: 90, attack: 15, defense: 8)
        
        self.attacks = ["Dolchstoß", "Giftklinge", "Meuchelmord", "Verstecken"]
        criticalChance = 0.25
    }
    
    // MARK: - Stealth System
    
    override func processStatusEffects() {
        super.processStatusEffects()
        
        if stealthDuration > 0 {
            stealthDuration -= 1
            if stealthDuration <= 0 {
                stealth = false
                removeStatus(.stealthed)
                print("\(name) wird wieder sichtbar.")
            }
        }
    }
    
    private func enterStealth() {
        stealth = true
        stealthDuration = 3
        applyStatus(.stealthed, duration: 3)
        print("💨 \(name) versteckt sich in den Schatten!")
    }
    
    // MARK: - Rogue Attacks
    
    override func performSpecificAttack(_ attackName: String, on target: Character) {
        switch attackName {
        case "Dolchstoß":
            performDaggerStrike(on: target)
        case "Giftklinge":
            performPoisonBlade(on: target)
        case "Meuchelmord":
            performAssassinate(on: target)
        case "Verstecken":
            enterStealth()
        default:
            super.performSpecificAttack(attackName, on: target)
        }
    }
    
    private func performDaggerStrike(on target: Character) {
        var damage = attackPower * 1.1
        var critChance = criticalChance + 0.1
        
        if stealth {
            damage *= 1.8
            critChance += 0.3
            stealth = false
            stealthDuration = 0
            removeStatus(.stealthed)
        }
        
        let oldCritChance = criticalChance
        criticalChance = critChance
        attack(target: target, damage: damage, attackType: .physical)
        criticalChance = oldCritChance
        
        print("🗡️ \(name) sticht \(target.name) mit dem Dolch!")
    }
    
    private func performPoisonBlade(on target: Character) {
        let damage = attackPower * 0.9
        attack(target: target, damage: damage, attackType: .poison)
        
        applyStatusEffect(.poisoned, to: target, duration: 3)
        poisonStacks += 1
        
        print("☠️ \(name) vergiftet \(target.name) mit der Giftklinge!")
    }
    
    private func performAssassinate(on target: Character) {
        var damage = attackPower * 2.0
        var critChance = criticalChance + 0.2
        
        if stealth {
            damage *= 1.5
            critChance += 0.3
            stealth = false
            stealthDuration = 0
            removeStatus(.stealthed)
        }
        
        let oldCritChance = criticalChance
        criticalChance = critChance
        attack(target: target, damage: damage, attackType: .physical)
        criticalChance = oldCritChance
        
        print("💀 \(name) versucht einen Meuchelmord an \(target.name)!")
    }
    
    // MARK: - Status Effect Implementation
    
    func applyStatusEffect(_ effect: CharacterStatus, to target: Character, duration: Int?) {
        guard availableStatusEffects.contains(effect) else { return }
        
        let intensity = effect == .poisoned ? Double(1 + Double(poisonStacks) * 0.2) : 1.0
        target.applyStatus(effect, duration: duration ?? 3, intensity: intensity)
        
        if effect == .poisoned {
            print("☠️ \(name) verstärkt die Vergiftung von \(target.name)!")
        }
    }
    
    // MARK: - Evasion
    
    override func takeDamage(_ amount: Double) {
        let evasionChance = agility / 100.0
        
        if Double.random(in: 0...1) < evasionChance {
            print("💨 \(name) weicht dem Angriff aus!")
            return
        }
        
        super.takeDamage(amount)
    }
}