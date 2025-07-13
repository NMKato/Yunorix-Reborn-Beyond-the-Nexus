//
//  Enemies.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Base Enemy Class

@MainActor
class Enemy: Character, AIControlled, Attackable {
    
    // MARK: - Enemy Properties
    
    var attacks: [String] = []
    var aiDifficulty: AIDifficulty
    var specialAbilities: [String] = []
    var pointValue: Int = 0
    
    // MARK: - Initialization
    
    init(name: String, maxHP: Double, attack: Double, defense: Double, difficulty: AIDifficulty) {
        self.aiDifficulty = difficulty
        super.init(name: name, maxHP: maxHP, attack: attack, defense: defense)
    }
    
    // MARK: - AI Control Methods
    
    func chooseRandomAction(availableTargets: [Character]) -> String {
        let aliveTargets = availableTargets.filter { $0.isAlive() }
        guard !aliveTargets.isEmpty else { return "wait" }
        
        switch aiDifficulty {
        case .easy:
            return chooseRandomAttack()
        case .medium:
            return chooseMediumAIAction(targets: aliveTargets)
        case .hard, .nightmare:
            return chooseOptimalAction(targets: aliveTargets)
        }
    }
    
    func performAITurn(against targets: [Character]) {
        guard !isIncapacitated() else { return }
        
        let aliveTargets = targets.filter { $0.isAlive() }
        guard !aliveTargets.isEmpty else { return }
        
        let action = chooseRandomAction(availableTargets: aliveTargets)
        
        let target = selectTarget(from: aliveTargets)
        executeAction(action, on: target, allTargets: aliveTargets)
    }
    
    func selectTarget(from targets: [Character]) -> Character {
        let aliveTargets = targets.filter { $0.isAlive() }
        guard !aliveTargets.isEmpty else { return targets.first! }
        
        switch aiDifficulty {
        case .easy:
            return aliveTargets.randomElement()!
        case .medium:
            return selectWeakestTarget(from: aliveTargets)
        case .hard, .nightmare:
            return selectOptimalTarget(from: aliveTargets)
        }
    }
    
    // MARK: - AI Decision Making
    
    private func chooseRandomAttack() -> String {
        return attacks.randomElement() ?? "Angriff"
    }
    
    private func chooseMediumAIAction(targets: [Character]) -> String {
        if healthPercentage() < 0.3 && canHealSelf() {
            return "heal"
        }
        
        if targets.count > 2 && hasAreaAttack() {
            return "area_attack"
        }
        
        return chooseRandomAttack()
    }
    
    private func chooseOptimalAction(targets: [Character]) -> String {
        if healthPercentage() < 0.2 && canHealSelf() {
            return "heal"
        }
        
        if targets.count > 1 && hasAreaAttack() {
            return "area_attack"
        }
        
        if hasStatusAttack() && targets.contains(where: { $0.currentStatus == .healthy }) {
            return "status_attack"
        }
        
        return getBestAttack()
    }
    
    private func selectWeakestTarget(from targets: [Character]) -> Character {
        return targets.min(by: { $0.healthPercentage() < $1.healthPercentage() }) ?? targets.first!
    }
    
    private func selectOptimalTarget(from targets: [Character]) -> Character {
        let heroes = targets.compactMap { $0 as? Hero }
        
        if let mage = heroes.first(where: { $0 is Mage }) {
            return mage
        }
        
        if let rogue = heroes.first(where: { $0 is Rogue }) {
            return rogue
        }
        
        return selectWeakestTarget(from: targets)
    }
    
    // MARK: - Action Execution
    
    private func executeAction(_ action: String, on target: Character, allTargets: [Character]) {
        switch action {
        case "heal":
            healSelf()
        case "area_attack":
            performAreaAttack(on: allTargets)
        case "status_attack":
            performStatusAttack(on: target)
        default:
            performAttack(on: target, attackIndex: nil)
        }
    }
    
    // MARK: - Attack Implementation
    
    func performAttack(on target: Character, attackIndex: Int?) {
        guard !isIncapacitated() else { return }
        
        let selectedAttack = attackIndex ?? Int.random(in: 0..<attacks.count)
        let attackName = attacks.isEmpty ? "Angriff" : attacks[selectedAttack]
        
        let damage = attackPower
        attack(target: target, damage: damage)
        
        print("\(name) greift \(target.name) mit \(attackName) an!")
    }
    
    func showAttackMenu() {
        print("=== \(name) Angriffe ===")
        for (index, attack) in attacks.enumerated() {
            print("\(index + 1). \(attack)")
        }
    }
    
    // MARK: - Special Abilities
    
    private func canHealSelf() -> Bool {
        return specialAbilities.contains("heal")
    }
    
    private func hasAreaAttack() -> Bool {
        return specialAbilities.contains("area_attack")
    }
    
    private func hasStatusAttack() -> Bool {
        return specialAbilities.contains("status_attack")
    }
    
    private func getBestAttack() -> String {
        return attacks.first ?? "Angriff"
    }
    
    private func healSelf() {
        let healAmount = maxHealthPoints * 0.3
        heal(healAmount)
        print("\(name) heilt sich selbst!")
    }
    
    private func performAreaAttack(on targets: [Character]) {
        let damage = attackPower * 0.7
        for target in targets where target.isAlive() {
            attack(target: target, damage: damage)
        }
        print("\(name) führt einen Flächenangriff aus!")
    }
    
    private func performStatusAttack(on target: Character) {
        let damage = attackPower * 0.8
        attack(target: target, damage: damage, attackType: .curse)
        print("\(name) greift \(target.name) mit einem verfluchten Angriff an!")
    }
}

// MARK: - Skeleton Enemy

@MainActor
class Skeleton: Enemy {
    
    init() {
        super.init(name: "Skelett", maxHP: 40, attack: 8, defense: 2, difficulty: .easy)
        self.attacks = ["Knochenhieb", "Klappern"]
        self.pointValue = 50
        criticalChance = 0.05
    }
    
    override func performAttack(on target: Character, attackIndex: Int?) {
        let attackName = attacks.randomElement() ?? "Angriff"
        
        switch attackName {
        case "Knochenhieb":
            let damage = attackPower * 1.1
            attack(target: target, damage: damage, attackType: .physical)
            print("💀 \(name) schlägt \(target.name) mit knöchernen Fäusten!")
            
        case "Klappern":
            let damage = attackPower * 0.8
            attack(target: target, damage: damage, attackType: .physical)
            if Double.random(in: 0...1) < 0.2 {
                target.applyStatus(.paralyzed, duration: 1)
                print("💀 \(name) klappert bedrohlich und paralysiert \(target.name)!")
            } else {
                print("💀 \(name) klappert bedrohlich!")
            }
            
        default:
            super.performAttack(on: target, attackIndex: attackIndex)
        }
    }
}

// MARK: - Orc Enemy

@MainActor
class Orc: Enemy {
    
    init() {
        super.init(name: "Ork", maxHP: 70, attack: 12, defense: 5, difficulty: .medium)
        self.attacks = ["Keulenhieb", "Wildes Brüllen", "Stampfen"]
        self.specialAbilities = ["status_attack"]
        self.pointValue = 100
        criticalChance = 0.08
    }
    
    override func performAttack(on target: Character, attackIndex: Int?) {
        let attackName = attacks.randomElement() ?? "Angriff"
        
        switch attackName {
        case "Keulenhieb":
            let damage = attackPower * 1.3
            attack(target: target, damage: damage, attackType: .physical)
            print("🏹 \(name) schlägt \(target.name) mit einer schweren Keule!")
            
        case "Wildes Brüllen":
            let damage = attackPower * 0.6
            attack(target: target, damage: damage, attackType: .physical)
            target.applyStatus(.cursed, duration: 2)
            print("🏹 \(name) brüllt wild und verängstigt \(target.name)!")
            
        case "Stampfen":
            let damage = attackPower * 1.1
            attack(target: target, damage: damage, attackType: .physical)
            if Double.random(in: 0...1) < 0.3 {
                target.applyStatus(.paralyzed, duration: 1)
                print("🏹 \(name) stampft und erschüttert \(target.name)!")
            } else {
                print("🏹 \(name) stampft heftig!")
            }
            
        default:
            super.performAttack(on: target, attackIndex: attackIndex)
        }
    }
}

// MARK: - Dragon Enemy

@MainActor
class Dragon: Enemy, AreaAttacker, StatusEffectCaster, ManaUser {
    
    // MARK: - Dragon Properties
    
    @Published var isFlying: Bool = false
    @Published var flightDuration: Int = 0
    var dragonScale: Double = 0.2
    var ancientWisdom: Double = 0.3
    var availableStatusEffects: [CharacterStatus] = [.cursed, .paralyzed, .poisoned]
    
    // MARK: - Initialization
    
    init() {
        super.init(name: "Drache", maxHP: 150, attack: 20, defense: 15, difficulty: .hard)
        
        // Set mana after super.init
        self.maxManaPoints = 80
        self.manaPoints = 80
        
        self.attacks = ["Feueratem", "Klauenhieb", "Schwanzschlag", "Fliegen"]
        self.specialAbilities = ["area_attack", "status_attack", "heal"]
        self.pointValue = 500
        criticalChance = 0.15
    }
    
    // MARK: - Mana Management
    
    func consumeMana(_ amount: Double) -> Bool {
        guard mana >= amount else { return false }
        mana -= amount
        return true
    }
    
    func regenerateMana(_ amount: Double) {
        mana = min(mana + amount, maxMana)
    }
    
    func hasEnoughMana(_ requiredMana: Double) -> Bool {
        return mana >= requiredMana
    }
    
    // MARK: - Dragon Combat
    
    override func performAttack(on target: Character, attackIndex: Int?) {
        let attackName = attacks.randomElement() ?? "Angriff"
        
        switch attackName {
        case "Feueratem":
            performFireBreath(on: [target])
        case "Klauenhieb":
            performClawAttack(on: target)
        case "Schwanzschlag":
            performTailSwipe(on: target)
        case "Fliegen":
            takeToSkies()
        default:
            super.performAttack(on: target, attackIndex: attackIndex)
        }
    }
    
    private func performFireBreath(on targets: [Character]) {
        guard consumeMana(25) else {
            performClawAttack(on: targets.first!)
            return
        }
        
        let damage = attackPower * 1.5
        areaAttack(targets: targets, damage: damage)
        print("🔥 \(name) speit verheerenden Feueratem!")
    }
    
    private func performClawAttack(on target: Character) {
        let damage = attackPower * 1.2
        if isFlying {
            attack(target: target, damage: damage * 1.3, attackType: .physical)
            print("🐉 \(name) stürzt herab und greift \(target.name) mit Klauen an!")
        } else {
            attack(target: target, damage: damage, attackType: .physical)
            print("🐉 \(name) schlägt \(target.name) mit mächtigen Klauen!")
        }
    }
    
    private func performTailSwipe(on target: Character) {
        let damage = attackPower * 1.0
        attack(target: target, damage: damage, attackType: .physical)
        
        if Double.random(in: 0...1) < 0.4 {
            target.applyStatus(.paralyzed, duration: 2)
            print("🐉 \(name) schlägt \(target.name) mit dem Schwanz zu Boden!")
        } else {
            print("🐉 \(name) schwingt den mächtigen Schwanz!")
        }
    }
    
    private func takeToSkies() {
        isFlying = true
        flightDuration = 3
        applyStatus(.flying, duration: 3)
        defenseValue += 5
        print("🐉 \(name) erhebt sich in die Lüfte!")
    }
    
    // MARK: - Dragon Status Processing
    
    override func processStatusEffects() {
        super.processStatusEffects()
        regenerateMana(15)
        
        if flightDuration > 0 {
            flightDuration -= 1
            if flightDuration <= 0 {
                isFlying = false
                removeStatus(.flying)
                defenseValue -= 5
                print("🐉 \(name) landet wieder!")
            }
        }
    }
    
    // MARK: - Area Attack Implementation
    
    func areaAttack(targets: [Character], damage: Double) {
        let reducedDamage = damage * 0.8
        for target in targets where target.isAlive() {
            attack(target: target, damage: reducedDamage, attackType: .fire)
        }
    }
    
    // MARK: - Status Effect Implementation
    
    func applyStatusEffect(_ effect: CharacterStatus, to target: Character, duration: Int?) {
        guard availableStatusEffects.contains(effect) else { return }
        
        let manaCost: Double = 20
        guard consumeMana(manaCost) else { return }
        
        target.applyStatus(effect, duration: duration ?? 3)
        print("🐉 \(name) belegt \(target.name) mit \(effect.description)!")
    }
    
    // MARK: - Damage Resistance
    
    override func calculateReducedDamage(_ incomingDamage: Double) -> Double {
        let scaleReduction = incomingDamage * dragonScale
        let magicalReduction = incomingDamage * ancientWisdom
        let totalReduction = scaleReduction + magicalReduction
        let reducedDamage = incomingDamage - totalReduction
        
        return super.calculateReducedDamage(reducedDamage)
    }
}

// MARK: - Final Boss

@MainActor
class FinalBoss: Enemy, AreaAttacker, Summoner, StatusEffectCaster {
    
    // MARK: - Boss Properties
    
    @Published var ultimateChargeCounter: Int = 0
    @Published var rageMode: Bool = false
    @Published var summonedCharacters: [Character] = []
    var maxSummons: Int = 2
    var hasUsedUltimate: Bool = false
    var availableStatusEffects: [CharacterStatus] = [.cursed, .paralyzed, .poisoned]
    
    var canSummon: Bool {
        return summonedCharacters.count < maxSummons
    }
    
    // MARK: - Initialization
    
    init() {
        super.init(name: "Dunkler Fürst", maxHP: 200, attack: 25, defense: 18, difficulty: .nightmare)
        
        self.attacks = ["Schattenhieb", "Seelenriss", "Dunkle Magie", "Beschwörung", "Ultimativer Angriff"]
        self.specialAbilities = ["area_attack", "status_attack", "summon", "ultimate"]
        self.pointValue = 1000
        criticalChance = 0.2
    }
    
    // MARK: - Boss Combat
    
    override func performAttack(on target: Character, attackIndex: Int?) {
        ultimateChargeCounter += 1
        
        if healthPercentage() < 0.3 && !rageMode {
            activateRageMode()
            return
        }
        
        if ultimateChargeCounter >= 3 && !hasUsedUltimate {
            performUltimateAttack(on: [target])
            return
        }
        
        let attackName = selectBossAttack()
        
        switch attackName {
        case "Schattenhieb":
            performShadowStrike(on: target)
        case "Seelenriss":
            performSoulRend(on: target)
        case "Dunkle Magie":
            performDarkMagic(on: target)
        case "Beschwörung":
            performSummon()
        case "Ultimativer Angriff":
            performUltimateAttack(on: [target])
        default:
            super.performAttack(on: target, attackIndex: attackIndex)
        }
    }
    
    private func selectBossAttack() -> String {
        if canSummon && summonedCharacters.filter({ $0.isAlive() }).isEmpty {
            return "Beschwörung"
        }
        
        if Double.random(in: 0...1) < 0.3 {
            return "Dunkle Magie"
        }
        
        return ["Schattenhieb", "Seelenriss"].randomElement()!
    }
    
    private func performShadowStrike(on target: Character) {
        var damage = attackPower * 1.4
        if rageMode { damage *= 1.3 }
        
        attack(target: target, damage: damage, attackType: .physical)
        print("👑 \(name) schlägt \(target.name) mit Schattenkraft!")
    }
    
    private func performSoulRend(on target: Character) {
        var damage = attackPower * 1.2
        if rageMode { damage *= 1.3 }
        
        attack(target: target, damage: damage, attackType: .curse)
        target.applyStatus(.cursed, duration: 4)
        print("👑 \(name) zerreißt die Seele von \(target.name)!")
    }
    
    private func performDarkMagic(on target: Character) {
        let effect = availableStatusEffects.randomElement()!
        applyStatusEffect(effect, to: target, duration: 3)
        print("👑 \(name) wirkt dunkle Magie auf \(target.name)!")
    }
    
    private func performSummon() {
        guard let minion = summon() else { return }
        print("👑 \(name) beschwört \(minion.name)!")
    }
    
    private func performUltimateAttack(on targets: [Character]) {
        hasUsedUltimate = true
        ultimateChargeCounter = 0
        
        let damage = attackPower * 3.0
        areaAttack(targets: targets, damage: damage)
        print("💀👑 \(name) entfesselt seinen ultimativen Angriff!")
    }
    
    private func activateRageMode() {
        rageMode = true
        attackPower *= 1.3
        applyStatus(.berserkerRage, duration: -1)
        print("👑💢 \(name) verfällt in rasende Wut!")
    }
    
    // MARK: - Area Attack Implementation
    
    func areaAttack(targets: [Character], damage: Double) {
        let reducedDamage = damage * 0.9
        for target in targets where target.isAlive() {
            attack(target: target, damage: reducedDamage, attackType: .curse)
        }
    }
    
    // MARK: - Summoner Implementation
    
    func summon() -> Character? {
        guard canSummon else { return nil }
        
        let minion = Orc()
        minion.name = "Dunkler Handlanger"
        minion.maxHealthPoints *= 0.7
        minion.healthPoints = minion.maxHealthPoints
        minion.attackPower *= 0.8
        
        summonedCharacters.append(minion)
        return minion
    }
    
    // MARK: - Status Effect Implementation
    
    func applyStatusEffect(_ effect: CharacterStatus, to target: Character, duration: Int?) {
        guard availableStatusEffects.contains(effect) else { return }
        
        let intensity = rageMode ? 1.5 : 1.0
        target.applyStatus(effect, duration: duration ?? 3, intensity: intensity)
    }
    
    // MARK: - Boss Status Processing
    
    override func processStatusEffects() {
        super.processStatusEffects()
        
        summonedCharacters = summonedCharacters.filter { $0.isAlive() }
    }
}