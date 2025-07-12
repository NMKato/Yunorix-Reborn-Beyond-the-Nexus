//
//  RPGProtocols.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Core Combat Protocols

protocol Attackable {
    var attackPower: Double { get set }
    var attacks: [String] { get }
    func performAttack(on target: Character, attackIndex: Int?)
    func showAttackMenu()
}

protocol Defendable {
    var defenseValue: Double { get set }
    var isDefending: Bool { get set }
    func defend()
    func calculateReducedDamage(_ incomingDamage: Double) -> Double
}

protocol AreaAttacker {
    func areaAttack(targets: [Character], damage: Double)
}

protocol Healable {
    func heal(target: Character, amount: Double)
    func canHeal(target: Character) -> Bool
}

// MARK: - Special Ability Protocols

protocol ManaUser {
    var mana: Double { get set }
    var maxMana: Double { get }
    func consumeMana(_ amount: Double) -> Bool
    func regenerateMana(_ amount: Double)
    func hasEnoughMana(_ requiredMana: Double) -> Bool
}

protocol StatusEffectCaster {
    var availableStatusEffects: [CharacterStatus] { get }
    func applyStatusEffect(_ effect: CharacterStatus, to target: Character, duration: Int?)
}

protocol StatusResistant {
    var resistances: [CharacterStatus] { get }
    func isResistantTo(_ status: CharacterStatus) -> Bool
}

protocol Summoner {
    var maxSummons: Int { get }
    var summonedCharacters: [Character] { get set }
    var canSummon: Bool { get }
    func summon() -> Character?
}

// MARK: - Control Protocols

protocol PlayerControlled {
    func showActionMenu()
    func processPlayerInput(_ input: String) -> Bool
    func performPlayerTurn(against availableTargets: [Character])
}

protocol AIControlled {
    func chooseRandomAction(availableTargets: [Character]) -> String
    func performAITurn(against targets: [Character])
    func selectTarget(from targets: [Character]) -> Character
}

// MARK: - Item System Protocols

protocol Usable {
    var isConsumable: Bool { get }
    var usageCount: Int { get set }
    var maxUsage: Int { get }
    var canBeUsed: Bool { get }
    mutating func use(on character: Character) -> Bool
}

// MARK: - Protocol Extensions with Default Implementations

extension StatusResistant {
    func isResistantTo(_ status: CharacterStatus) -> Bool {
        return resistances.contains(status)
    }
}

extension Defendable {
    func calculateReducedDamage(_ incomingDamage: Double) -> Double {
        let reduction = isDefending ? defenseValue * 1.5 : defenseValue
        return max(0, incomingDamage - reduction)
    }
}

extension Usable {
    var canBeUsed: Bool {
        return usageCount < maxUsage || maxUsage == -1
    }
}