//
//  Character.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

@MainActor
class Character: ObservableObject, CustomStringConvertible, Identifiable {
    
    // MARK: - Core Properties
    
    let id = UUID()
    @Published var name: String
    @Published var healthPoints: Double
    @Published var maxHealthPoints: Double
    @Published var manaPoints: Double = 100.0
    @Published var maxManaPoints: Double = 100.0
    @Published var currentStatus: CharacterStatus = .healthy
    @Published var activeStatusEffects: [StatusEffectInstance] = []
    
    // MARK: - Combat Stats
    
    var attackPower: Double
    var defenseValue: Double
    var criticalChance: Double = 0.1
    var isDefending: Bool = false
    
    // MARK: - Computed Properties for Compatibility
    
    var currentHealth: Double {
        get { return healthPoints }
        set { healthPoints = newValue }
    }
    
    var maxHealth: Double {
        get { return maxHealthPoints }
        set { maxHealthPoints = newValue }
    }
    
    var currentMana: Double {
        get { return manaPoints }
        set { manaPoints = newValue }
    }
    
    var mana: Double {
        get { return manaPoints }
        set { manaPoints = newValue }
    }
    
    var maxMana: Double {
        get { return maxManaPoints }
        set { maxManaPoints = newValue }
    }
    
    // MARK: - Initiative and Turn Management
    
    var initiative: Int {
        return Int.random(in: 1...20)
    }
    
    // MARK: - Initialization
    
    init(name: String, maxHP: Double, attack: Double, defense: Double) {
        self.name = name
        self.maxHealthPoints = maxHP
        self.healthPoints = maxHP
        self.attackPower = attack
        self.defenseValue = defense
        updateStatusBasedOnHealth()
    }
    
    // MARK: - Health Management
    
    func takeDamage(_ amount: Double) {
        let actualDamage = calculateReducedDamage(amount)
        healthPoints = max(0, healthPoints - actualDamage)
        updateStatusBasedOnHealth()
        
        if healthPoints <= 0 {
            applyStatus(.defeated)
        }
    }
    
    func heal(_ amount: Double) {
        guard !isDefeated() else { return }
        healthPoints = min(healthPoints + amount, maxHealthPoints)
        updateStatusBasedOnHealth()
        
        if healthPoints > maxHealthPoints * 0.25 && currentStatus == .wounded {
            removeStatus(.wounded)
        }
    }
    
    func calculateReducedDamage(_ incomingDamage: Double) -> Double {
        let baseReduction = defenseValue
        let defendingBonus = isDefending ? defenseValue * 0.5 : 0
        let totalReduction = baseReduction + defendingBonus
        
        return max(0, incomingDamage - totalReduction)
    }
    
    // MARK: - Status Effect Management
    
    func applyStatus(_ status: CharacterStatus, duration: Int = -1, intensity: Double = 1.0) {
        guard !hasStatus(status) else { return }
        
        let statusInstance = StatusEffectInstance(effect: status, duration: duration, intensity: intensity)
        activeStatusEffects.append(statusInstance)
        
        if status != .healthy {
            currentStatus = status
        }
    }
    
    func removeStatus(_ status: CharacterStatus) {
        activeStatusEffects.removeAll { $0.effect == status }
        updateCurrentStatus()
    }
    
    func hasStatus(_ status: CharacterStatus) -> Bool {
        return activeStatusEffects.contains { $0.effect == status }
    }
    
    func processStatusEffects() {
        var effectsToRemove: [Int] = []
        
        for (index, var effect) in activeStatusEffects.enumerated() {
            switch effect.effect {
            case .poisoned:
                takeDamage(5.0 * effect.intensity)
                
            case .cursed:
                let curseDamage = maxHealthPoints * 0.1 * effect.intensity
                takeDamage(curseDamage)
                
            case .berserkerRage:
                break
                
            case .paralyzed:
                break
                
            default:
                break
            }
            
            if !effect.decrementDuration() {
                effectsToRemove.append(index)
            } else {
                activeStatusEffects[index] = effect
            }
        }
        
        for index in effectsToRemove.reversed() {
            activeStatusEffects.remove(at: index)
        }
        
        updateCurrentStatus()
    }
    
    private func updateStatusBasedOnHealth() {
        let healthPercentage = healthPoints / maxHealthPoints
        
        if healthPoints <= 0 {
            currentStatus = .defeated
        } else if healthPercentage < 0.25 && !hasStatus(.wounded) {
            applyStatus(.wounded)
        }
    }
    
    private func updateCurrentStatus() {
        if healthPoints <= 0 {
            currentStatus = .defeated
            return
        }
        
        let priorityOrder: [CharacterStatus] = [.paralyzed, .cursed, .poisoned, .berserkerRage, .defending, .stealthed, .flying, .wounded, .healthy]
        
        for status in priorityOrder {
            if hasStatus(status) {
                currentStatus = status
                return
            }
        }
        
        currentStatus = healthPoints < maxHealthPoints * 0.25 ? .wounded : .healthy
    }
    
    // MARK: - Combat Actions
    
    func attack(target: Character, damage: Double, attackType: AttackType = .physical) {
        guard !isIncapacitated() else { return }
        
        var finalDamage = damage * attackType.damageMultiplier
        
        if isCriticalHit() {
            finalDamage *= 1.5
        }
        
        if hasStatus(.berserkerRage) {
            finalDamage *= 1.3
        }
        
        if hasStatus(.stealthed) {
            finalDamage *= 1.8
            removeStatus(.stealthed)
        }
        
        target.takeDamage(finalDamage)
        
        if let statusEffect = attackType.statusEffect {
            let statusChance = Double.random(in: 0...1)
            if statusChance < 0.3 {
                target.applyStatus(statusEffect, duration: 3)
            }
        }
    }
    
    func defend() {
        guard !isIncapacitated() else { return }
        isDefending = true
        applyStatus(.defending, duration: 1)
    }
    
    private func isCriticalHit() -> Bool {
        var chance = criticalChance
        
        if hasStatus(.stealthed) {
            chance += 0.2
        }
        
        return Double.random(in: 0...1) < chance
    }
    
    // MARK: - Status Queries
    
    func isDefeated() -> Bool {
        return healthPoints <= 0 || currentStatus == .defeated
    }
    
    func isIncapacitated() -> Bool {
        return isDefeated() || hasStatus(.paralyzed)
    }
    
    func healthPercentage() -> Double {
        return healthPoints / maxHealthPoints
    }
    
    func isAlive() -> Bool {
        return !isDefeated()
    }
    
    // MARK: - Resource Management
    
    func heal(_ amount: Int) {
        let healingAmount = Double(amount)
        healthPoints = min(maxHealthPoints, healthPoints + healingAmount)
        updateStatusBasedOnHealth()
    }
    
    func restoreMana(_ amount: Int) {
        let restorationAmount = Double(amount)
        manaPoints = min(maxManaPoints, manaPoints + restorationAmount)
    }
    
    func gainExperience(_ amount: Int) {
        // Base implementation - can be overridden by Hero subclass
        print("\(name) gained \(amount) experience")
    }
    
    // MARK: - Display
    
    var description: String {
        let healthBar = createHealthBar()
        let statusText = currentStatus.emoji + " " + currentStatus.description
        return "\(name) | \(healthBar) | \(statusText)"
    }
    
    private func createHealthBar() -> String {
        let barLength = 10
        let filledLength = Int((healthPercentage() * Double(barLength)).rounded())
        let emptyLength = barLength - filledLength
        
        let filledBar = String(repeating: "█", count: filledLength)
        let emptyBar = String(repeating: "░", count: emptyLength)
        
        return "[\(filledBar)\(emptyBar)] \(Int(healthPoints))/\(Int(maxHealthPoints))"
    }
    
    func displayDetailedStatus() -> String {
        var details = [description]
        
        if !activeStatusEffects.isEmpty {
            details.append("Aktive Effekte:")
            for effect in activeStatusEffects {
                let durationText = effect.duration == -1 ? "∞" : "\(effect.duration)"
                details.append("  • \(effect.effect.emoji) \(effect.effect.description) (\(durationText))")
            }
        }
        
        return details.joined(separator: "\n")
    }
}
