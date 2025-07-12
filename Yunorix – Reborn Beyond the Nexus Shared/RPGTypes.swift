//
//  RPGTypes.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Character Status System

enum CharacterStatus: CaseIterable, Equatable {
    case healthy
    case wounded
    case cursed
    case paralyzed
    case poisoned
    case defeated
    case berserkerRage
    case defending
    case stealthed
    case flying
    
    var isNegative: Bool {
        switch self {
        case .cursed, .paralyzed, .poisoned, .defeated:
            return true
        case .healthy, .wounded, .berserkerRage, .defending, .stealthed, .flying:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .healthy: return "Gesund"
        case .wounded: return "Verwundet"
        case .cursed: return "Verflucht"
        case .paralyzed: return "Gelähmt"
        case .poisoned: return "Vergiftet"
        case .defeated: return "Besiegt"
        case .berserkerRage: return "Berserker-Wut"
        case .defending: return "Verteidigt"
        case .stealthed: return "Versteckt"
        case .flying: return "Fliegend"
        }
    }
    
    var emoji: String {
        switch self {
        case .healthy: return "💚"
        case .wounded: return "💛"
        case .cursed: return "💜"
        case .paralyzed: return "⚡"
        case .poisoned: return "💚"
        case .defeated: return "💀"
        case .berserkerRage: return "🔥"
        case .defending: return "🛡️"
        case .stealthed: return "👻"
        case .flying: return "🕊️"
        }
    }
}

// MARK: - Item System Types

enum ItemType: CaseIterable {
    case healing
    case damage
    case buff
    case debuff
    case special
    
    var description: String {
        switch self {
        case .healing: return "Heilung"
        case .damage: return "Schaden"
        case .buff: return "Verstärkung"
        case .debuff: return "Schwächung"
        case .special: return "Spezial"
        }
    }
    
    var emoji: String {
        switch self {
        case .healing: return "💊"
        case .damage: return "💣"
        case .buff: return "⚡"
        case .debuff: return "☠️"
        case .special: return "✨"
        }
    }
}

// MARK: - Combat Types

enum AttackType {
    case physical
    case magical
    case fire
    case ice
    case lightning
    case poison
    case curse
    
    var description: String {
        switch self {
        case .physical: return "Physisch"
        case .magical: return "Magisch"
        case .fire: return "Feuer"
        case .ice: return "Eis"
        case .lightning: return "Blitz"
        case .poison: return "Gift"
        case .curse: return "Fluch"
        }
    }
    
    var statusEffect: CharacterStatus? {
        switch self {
        case .ice: return .paralyzed
        case .poison: return .poisoned
        case .curse: return .cursed
        default: return nil
        }
    }
    
    var damageMultiplier: Double {
        switch self {
        case .physical: return 1.0
        case .magical: return 1.1
        case .fire: return 1.2
        case .ice: return 0.9
        case .lightning: return 1.3
        case .poison: return 0.8
        case .curse: return 0.7
        }
    }
}

// MARK: - AI Difficulty Levels

enum AIDifficulty: Double, CaseIterable {
    case easy = 0.3
    case medium = 0.6
    case hard = 0.9
    case nightmare = 1.0
    
    var description: String {
        switch self {
        case .easy: return "Leicht"
        case .medium: return "Mittel"
        case .hard: return "Schwer"
        case .nightmare: return "Alptraum"
        }
    }
}

// MARK: - Status Effect Duration Tracking

struct StatusEffectInstance {
    let effect: CharacterStatus
    var duration: Int
    let intensity: Double
    
    init(effect: CharacterStatus, duration: Int = -1, intensity: Double = 1.0) {
        self.effect = effect
        self.duration = duration
        self.intensity = intensity
    }
    
    mutating func decrementDuration() -> Bool {
        if duration > 0 {
            duration -= 1
            return duration > 0
        }
        return duration == -1
    }
}

// MARK: - Combat Action Types

enum CombatAction {
    case attack(attackIndex: Int)
    case defend
    case useItem(itemIndex: Int, targetIndex: Int?)
    case special(abilityIndex: Int)
    case flee
    
    var description: String {
        switch self {
        case .attack: return "Angriff"
        case .defend: return "Verteidigung"
        case .useItem: return "Item benutzen"
        case .special: return "Spezialfähigkeit"
        case .flee: return "Flucht"
        }
    }
}