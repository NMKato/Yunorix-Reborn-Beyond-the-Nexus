//
//  Items.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Item Structure

struct Item: Usable, CustomStringConvertible, Identifiable, Equatable {
    
    let id = UUID()
    let name: String
    let itemType: ItemType
    let effect: Double
    var usageCount: Int
    let maxUsage: Int
    let isConsumable: Bool
    let itemDescription: String
    let rarity: ItemRarity
    
    // MARK: - Initialization
    
    init(name: String, type: ItemType, effect: Double, maxUsage: Int = 1, description: String, rarity: ItemRarity = .common) {
        self.name = name
        self.itemType = type
        self.effect = effect
        self.maxUsage = maxUsage
        self.usageCount = 0
        self.isConsumable = maxUsage != -1
        self.itemDescription = description
        self.rarity = rarity
    }
    
    // MARK: - Usable Protocol Implementation
    
    @MainActor mutating func use(on character: Character) -> Bool {
        guard canBeUsed else { return false }
        
        let success = applyEffect(to: character)
        
        if success && isConsumable {
            usageCount += 1
        }
        
        return success
    }
    
    // MARK: - Effect Application
    
    @MainActor private func applyEffect(to character: Character) -> Bool {
        switch itemType {
        case .healing:
            return applyHealingEffect(to: character)
        case .damage:
            return applyDamageEffect(to: character)
        case .buff:
            return applyBuffEffect(to: character)
        case .debuff:
            return applyDebuffEffect(to: character)
        case .special:
            return applySpecialEffect(to: character)
        }
    }
    
    @MainActor private func applyHealingEffect(to character: Character) -> Bool {
        guard !character.isDefeated() else { return false }
        
        switch name {
        case "Kleiner Heiltrank":
            character.heal(effect)
            print("💚 \(character.name) wurde um \(Int(effect)) LP geheilt!")
            
        case "Heiltrank":
            character.heal(effect)
            print("💚 \(character.name) wurde um \(Int(effect)) LP geheilt!")
            
        case "Großer Heiltrank":
            character.heal(effect)
            print("💚 \(character.name) wurde um \(Int(effect)) LP geheilt!")
            
        case "Vollheilung":
            character.heal(character.maxHealthPoints)
            print("✨ \(character.name) wurde vollständig geheilt!")
            
        case "Mana-Trank":
            if let manaUser = character as? ManaUser {
                manaUser.regenerateMana(effect)
                print("💙 \(character.name) regeneriert \(Int(effect)) Mana!")
            }
            
        case "Wiederbelebung":
            if character.isDefeated() {
                character.healthPoints = character.maxHealthPoints * 0.5
                character.removeStatus(.defeated)
                print("🌟 \(character.name) wurde wiederbelebt!")
            }
            
        default:
            character.heal(effect)
            print("💚 \(character.name) wurde geheilt!")
        }
        
        return true
    }
    
    @MainActor private func applyDamageEffect(to character: Character) -> Bool {
        character.takeDamage(effect)
        print("💥 \(character.name) erleidet \(Int(effect)) Schaden!")
        return true
    }
    
    @MainActor private func applyBuffEffect(to character: Character) -> Bool {
        switch name {
        case "Kraft-Elixier":
            character.attackPower += effect
            print("⚡ \(character.name)s Angriffskraft steigt um \(Int(effect))!")
            
        case "Verteidigungs-Elixier":
            character.defenseValue += effect
            print("🛡️ \(character.name)s Verteidigung steigt um \(Int(effect))!")
            
        case "Geschwindigkeits-Elixier":
            character.criticalChance += effect / 100
            print("💨 \(character.name)s kritische Trefferchance steigt!")
            
        case "Berserker-Elixier":
            character.applyStatus(.berserkerRage, duration: Int(effect))
            print("🔥 \(character.name) verfällt in Berserker-Wut!")
            
        default:
            character.attackPower += effect
            print("⚡ \(character.name) wird gestärkt!")
        }
        
        return true
    }
    
    @MainActor private func applyDebuffEffect(to character: Character) -> Bool {
        switch name {
        case "Giftflasche":
            character.applyStatus(.poisoned, duration: Int(effect))
            print("☠️ \(character.name) wurde vergiftet!")
            
        case "Fluch-Schriftrolle":
            character.applyStatus(.cursed, duration: Int(effect))
            print("💜 \(character.name) wurde verflucht!")
            
        case "Lähmungs-Pulver":
            character.applyStatus(.paralyzed, duration: Int(effect))
            print("⚡ \(character.name) wurde gelähmt!")
            
        case "Schwächungs-Trank":
            character.attackPower = max(1, character.attackPower - effect)
            print("😵 \(character.name)s Angriffskraft sinkt!")
            
        default:
            character.applyStatus(.cursed, duration: Int(effect))
            print("💜 \(character.name) wurde geschwächt!")
        }
        
        return true
    }
    
    @MainActor private func applySpecialEffect(to character: Character) -> Bool {
        switch name {
        case "Reinigung":
            character.activeStatusEffects.removeAll { $0.effect.isNegative }
            character.currentStatus = character.healthPercentage() < 0.25 ? .wounded : .healthy
            print("✨ \(character.name) wurde von allen negativen Effekten befreit!")
            
        case "Mystischer Kristall":
            if let manaUser = character as? ManaUser {
                manaUser.regenerateMana(manaUser.maxMana)
                character.heal(character.maxHealthPoints * 0.3)
                print("💎 \(character.name) wird von mystischer Energie erfüllt!")
            } else {
                character.heal(character.maxHealthPoints * 0.5)
                print("💎 \(character.name) wird von mystischer Energie geheilt!")
            }
            
        case "Schutz-Amulett":
            character.defenseValue += effect
            character.applyStatus(.defending, duration: 5)
            print("🔮 \(character.name) wird von magischem Schutz umhüllt!")
            
        case "Unsichtbarkeits-Trank":
            if let rogue = character as? Rogue {
                rogue.stealth = true
                rogue.stealthDuration = Int(effect)
                character.applyStatus(.stealthed, duration: Int(effect))
                print("👻 \(character.name) wird unsichtbar!")
            }
            
        default:
            character.heal(effect)
            print("✨ \(character.name) erfährt einen mystischen Effekt!")
        }
        
        return true
    }
    
    // MARK: - Display
    
    var description: String {
        let usageText = maxUsage == -1 ? "∞" : "\(maxUsage - usageCount)/\(maxUsage)"
        let rarityIcon = rarity.icon
        return "\(rarityIcon) \(name) (\(usageText)) - \(itemDescription)"
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.name == rhs.name && lhs.itemType == rhs.itemType
    }
}

// MARK: - Item Rarity

enum ItemRarity: CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    
    var description: String {
        switch self {
        case .common: return "Gewöhnlich"
        case .uncommon: return "Ungewöhnlich"
        case .rare: return "Selten"
        case .epic: return "Episch"
        case .legendary: return "Legendär"
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "⚪"
        case .uncommon: return "🟢"
        case .rare: return "🔵"
        case .epic: return "🟣"
        case .legendary: return "🟡"
        }
    }
    
    var dropChance: Double {
        switch self {
        case .common: return 0.6
        case .uncommon: return 0.25
        case .rare: return 0.1
        case .epic: return 0.04
        case .legendary: return 0.01
        }
    }
}

// MARK: - Item Factory

struct ItemFactory {
    
    static let healingItems = [
        Item(name: "Kleiner Heiltrank", type: .healing, effect: 25, description: "Stellt 25 LP wieder her"),
        Item(name: "Heiltrank", type: .healing, effect: 50, description: "Stellt 50 LP wieder her", rarity: .uncommon),
        Item(name: "Großer Heiltrank", type: .healing, effect: 100, description: "Stellt 100 LP wieder her", rarity: .rare),
        Item(name: "Vollheilung", type: .healing, effect: 9999, description: "Stellt alle LP wieder her", rarity: .epic),
        Item(name: "Mana-Trank", type: .healing, effect: 50, description: "Stellt 50 Mana wieder her"),
        Item(name: "Wiederbelebung", type: .healing, effect: 1, description: "Belebt einen besiegten Charakter wieder", rarity: .legendary)
    ]
    
    static let damageItems = [
        Item(name: "Wurfmesser", type: .damage, effect: 20, maxUsage: 3, description: "Verursacht 20 Schaden"),
        Item(name: "Sprengbombe", type: .damage, effect: 40, description: "Verursacht 40 Schaden", rarity: .uncommon),
        Item(name: "Blitzkugel", type: .damage, effect: 60, description: "Verursacht 60 Blitzschaden", rarity: .rare),
        Item(name: "Drachenbombe", type: .damage, effect: 100, description: "Verursacht verheerenden Schaden", rarity: .epic)
    ]
    
    static let buffItems = [
        Item(name: "Kraft-Elixier", type: .buff, effect: 5, description: "Erhöht Angriff permanent um 5"),
        Item(name: "Verteidigungs-Elixier", type: .buff, effect: 3, description: "Erhöht Verteidigung permanent um 3"),
        Item(name: "Geschwindigkeits-Elixier", type: .buff, effect: 10, description: "Erhöht kritische Chance um 10%", rarity: .uncommon),
        Item(name: "Berserker-Elixier", type: .buff, effect: 5, description: "Aktiviert Berserker-Wut für 5 Runden", rarity: .rare)
    ]
    
    static let debuffItems = [
        Item(name: "Giftflasche", type: .debuff, effect: 3, description: "Vergiftet Ziel für 3 Runden"),
        Item(name: "Fluch-Schriftrolle", type: .debuff, effect: 4, description: "Verflucht Ziel für 4 Runden", rarity: .uncommon),
        Item(name: "Lähmungs-Pulver", type: .debuff, effect: 2, description: "Lähmt Ziel für 2 Runden", rarity: .rare),
        Item(name: "Schwächungs-Trank", type: .debuff, effect: 8, description: "Reduziert Angriff permanent um 8")
    ]
    
    static let specialItems = [
        Item(name: "Reinigung", type: .special, effect: 1, description: "Entfernt alle negativen Statuseffekte", rarity: .uncommon),
        Item(name: "Mystischer Kristall", type: .special, effect: 1, description: "Stellt LP und Mana vollständig wieder her", rarity: .epic),
        Item(name: "Schutz-Amulett", type: .special, effect: 10, description: "Erhöht Verteidigung um 10 für 5 Runden", rarity: .rare),
        Item(name: "Unsichtbarkeits-Trank", type: .special, effect: 3, description: "Macht unsichtbar für 3 Runden", rarity: .legendary)
    ]
    
    static func createRandomItem() -> Item {
        let allItems = healingItems + damageItems + buffItems + debuffItems + specialItems
        return allItems.randomElement()!
    }
    
    static func createRandomItemByRarity() -> Item {
        let randomValue = Double.random(in: 0...1)
        var cumulativeChance = 0.0
        
        for rarity in ItemRarity.allCases.reversed() {
            cumulativeChance += rarity.dropChance
            if randomValue <= cumulativeChance {
                return createItemOfRarity(rarity)
            }
        }
        
        return createItemOfRarity(.common)
    }
    
    static func createItemOfRarity(_ rarity: ItemRarity) -> Item {
        let allItems = healingItems + damageItems + buffItems + debuffItems + specialItems
        let itemsOfRarity = allItems.filter { $0.rarity == rarity }
        
        if itemsOfRarity.isEmpty {
            return allItems.randomElement()!
        }
        
        return itemsOfRarity.randomElement()!
    }
    
    @MainActor static func createLootForEnemy(_ enemy: Enemy) -> [Item] {
        var loot: [Item] = []
        let baseDropChance = 0.7
        
        var itemCount = 1
        if enemy.pointValue > 200 {
            itemCount = Int.random(in: 1...3)
        }
        
        for _ in 0..<itemCount {
            if Double.random(in: 0...1) < baseDropChance {
                let rarityBonus = Double(enemy.pointValue) / 1000.0
                
                if Double.random(in: 0...1) < rarityBonus {
                    loot.append(createRandomItemByRarity())
                } else {
                    loot.append(createRandomItem())
                }
            }
        }
        
        return loot
    }
}