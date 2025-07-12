//
//  Inventory.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation

// MARK: - Inventory Management

@MainActor
struct Inventory: CustomStringConvertible {
    
    // MARK: - Properties
    
    private var items: [InventorySlot] = []
    let maxCapacity: Int
    
    var count: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var isFull: Bool {
        return items.count >= maxCapacity
    }
    
    var usedSlots: Int {
        return items.count
    }
    
    var availableSlots: Int {
        return maxCapacity - usedSlots
    }
    
    // MARK: - Initialization
    
    init(maxCapacity: Int) {
        self.maxCapacity = maxCapacity
    }
    
    // MARK: - Item Management
    
    mutating func addItem(_ item: Item) -> Bool {
        if let existingSlotIndex = items.firstIndex(where: { $0.item == item }) {
            items[existingSlotIndex].quantity += 1
            print("✅ \(item.name) wurde zum Inventar hinzugefügt (Stapel: \(items[existingSlotIndex].quantity))")
            return true
        }
        
        guard !isFull else {
            print("❌ Inventar ist voll! \(item.name) konnte nicht hinzugefügt werden.")
            return false
        }
        
        let newSlot = InventorySlot(item: item, quantity: 1)
        items.append(newSlot)
        print("✅ \(item.name) wurde zum Inventar hinzugefügt.")
        return true
    }
    
    mutating func addItems(_ itemsToAdd: [Item]) -> [Item] {
        var failedItems: [Item] = []
        
        for item in itemsToAdd {
            if !addItem(item) {
                failedItems.append(item)
            }
        }
        
        return failedItems
    }
    
    mutating func removeItem(at index: Int) -> Item? {
        guard index >= 0 && index < items.count else { return nil }
        
        var slot = items[index]
        let item = slot.item
        
        slot.quantity -= 1
        
        if slot.quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index] = slot
        }
        
        print("🗑️ \(item.name) wurde aus dem Inventar entfernt.")
        return item
    }
    
    mutating func removeItemByName(_ name: String) -> Item? {
        guard let index = items.firstIndex(where: { $0.item.name == name }) else { return nil }
        return removeItem(at: index)
    }
    
    mutating func useItem(at index: Int, on character: Character) -> Bool {
        guard index >= 0 && index < items.count else {
            print("❌ Ungültiger Inventar-Index.")
            return false
        }
        
        var slot = items[index]
        var item = slot.item
        
        guard item.canBeUsed else {
            print("❌ \(item.name) kann nicht mehr verwendet werden.")
            return false
        }
        
        let success = item.use(on: character)
        
        if success {
            if item.isConsumable && item.usageCount >= item.maxUsage {
                items.remove(at: index)
                print("🗑️ \(item.name) wurde verbraucht und entfernt.")
            } else {
                slot.item = item
                items[index] = slot
            }
            
            return true
        }
        
        return false
    }
    
    mutating func useItemByName(_ name: String, on character: Character) -> Bool {
        guard let index = items.firstIndex(where: { $0.item.name == name }) else {
            print("❌ \(name) nicht im Inventar gefunden.")
            return false
        }
        
        return useItem(at: index, on: character)
    }
    
    // MARK: - Inventory Queries
    
    func hasItem(named name: String) -> Bool {
        return items.contains { $0.item.name == name }
    }
    
    func getItem(at index: Int) -> Item? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index].item
    }
    
    func getItemsByType(_ type: ItemType) -> [Item] {
        return items.compactMap { $0.item.itemType == type ? $0.item : nil }
    }
    
    func getItemsByRarity(_ rarity: ItemRarity) -> [Item] {
        return items.compactMap { $0.item.rarity == rarity ? $0.item : nil }
    }
    
    func findItems(matching predicate: (Item) -> Bool) -> [Item] {
        return items.compactMap { predicate($0.item) ? $0.item : nil }
    }
    
    // MARK: - Inventory Sorting
    
    mutating func sortByType() {
        let sortedItems = items.sorted { lhs, rhs in
            if lhs.item.itemType == rhs.item.itemType {
                return lhs.item.name < rhs.item.name
            }
            return typeOrder(lhs.item.itemType) < typeOrder(rhs.item.itemType)
        }
        items = sortedItems
    }
    
    mutating func sortByRarity() {
        let sortedItems = items.sorted { lhs, rhs in
            if lhs.item.rarity == rhs.item.rarity {
                return lhs.item.name < rhs.item.name
            }
            return rarityOrder(lhs.item.rarity) > rarityOrder(rhs.item.rarity)
        }
        items = sortedItems
    }
    
    mutating func sortByName() {
        items = items.sorted { $0.item.name < $1.item.name }
    }
    
    private func typeOrder(_ type: ItemType) -> Int {
        switch type {
        case .healing: return 0
        case .buff: return 1
        case .special: return 2
        case .damage: return 3
        case .debuff: return 4
        }
    }
    
    private func rarityOrder(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .legendary: return 5
        case .epic: return 4
        case .rare: return 3
        case .uncommon: return 2
        case .common: return 1
        }
    }
    
    // MARK: - Interactive Menu
    
    func showMenu(for currentCharacter: Character) -> Bool {
        guard !isEmpty else {
            print("\n📦 Das Inventar ist leer!")
            return false
        }
        
        print("\n📦 === Inventar von \(currentCharacter.name) ===")
        print("Plätze: \(usedSlots)/\(maxCapacity)")
        print()
        
        for (index, slot) in items.enumerated() {
            let quantityText = slot.quantity > 1 ? " x\(slot.quantity)" : ""
            print("\(index + 1). \(slot.item.description)\(quantityText)")
        }
        
        print("\nOptionen:")
        print("• Zahl eingeben: Item verwenden")
        print("• 'info X': Details zu Item X anzeigen")
        print("• 'sort type/rarity/name': Inventar sortieren")
        print("• 'exit': Menü verlassen")
        
        return true
    }
    
    mutating func processMenuInput(_ input: String, character: Character) -> Bool {
        let components = input.lowercased().split(separator: " ")
        
        guard !components.isEmpty else { return false }
        
        let command = String(components[0])
        
        switch command {
        case "exit", "zurück", "cancel":
            return true
            
        case "info":
            if components.count > 1, let index = Int(components[1]), index > 0 && index <= items.count {
                showItemDetails(at: index - 1)
            } else {
                print("❌ Ungültige Syntax. Verwende 'info X' (X = Item-Nummer)")
            }
            return false
            
        case "sort":
            if components.count > 1 {
                handleSortCommand(String(components[1]))
            } else {
                print("❌ Ungültige Syntax. Verwende 'sort type/rarity/name'")
            }
            return false
            
        default:
            if let index = Int(command), index > 0 && index <= items.count {
                let success = useItem(at: index - 1, on: character)
                if success {
                    print("✅ Item wurde erfolgreich verwendet!")
                } else {
                    print("❌ Item konnte nicht verwendet werden.")
                }
                return false
            } else {
                print("❌ Ungültige Eingabe. Gib eine Zahl zwischen 1 und \(items.count) ein.")
                return false
            }
        }
    }
    
    private func showItemDetails(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        
        let slot = items[index]
        let item = slot.item
        
        print("\n🔍 === Item-Details ===")
        print("Name: \(item.name)")
        print("Typ: \(item.itemType.emoji) \(item.itemType.description)")
        print("Seltenheit: \(item.rarity.icon) \(item.rarity.description)")
        print("Effekt: \(Int(item.effect))")
        print("Verwendungen: \(item.maxUsage == -1 ? "Unbegrenzt" : "\(item.maxUsage - item.usageCount)/\(item.maxUsage)")")
        print("Anzahl: \(slot.quantity)")
        print("Beschreibung: \(item.description)")
        print("Verbrauchbar: \(item.isConsumable ? "Ja" : "Nein")")
        print()
    }
    
    private mutating func handleSortCommand(_ sortType: String) {
        switch sortType {
        case "type", "typ":
            sortByType()
            print("📦 Inventar nach Typ sortiert.")
        case "rarity", "seltenheit":
            sortByRarity()
            print("📦 Inventar nach Seltenheit sortiert.")
        case "name", "namen":
            sortByName()
            print("📦 Inventar alphabetisch sortiert.")
        default:
            print("❌ Unbekannter Sortiertyp. Verwende 'type', 'rarity' oder 'name'.")
        }
    }
    
    // MARK: - Inventory Statistics
    
    func getStatistics() -> InventoryStatistics {
        var typeCount: [ItemType: Int] = [:]
        var rarityCount: [ItemRarity: Int] = [:]
        var totalValue = 0
        
        for slot in items {
            typeCount[slot.item.itemType, default: 0] += slot.quantity
            rarityCount[slot.item.rarity, default: 0] += slot.quantity
            totalValue += slot.quantity * rarityValue(slot.item.rarity)
        }
        
        return InventoryStatistics(
            totalItems: count,
            usedSlots: usedSlots,
            availableSlots: availableSlots,
            typeDistribution: typeCount,
            rarityDistribution: rarityCount,
            estimatedValue: totalValue
        )
    }
    
    private func rarityValue(_ rarity: ItemRarity) -> Int {
        switch rarity {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 250
        }
    }
    
    // MARK: - Display
    
    var description: String {
        guard !isEmpty else { return "📦 Leeres Inventar (0/\(maxCapacity))" }
        
        var result = "📦 Inventar (\(usedSlots)/\(maxCapacity)):\n"
        
        for (index, slot) in items.enumerated() {
            let quantityText = slot.quantity > 1 ? " x\(slot.quantity)" : ""
            result += "\(index + 1). \(slot.item.name)\(quantityText)\n"
        }
        
        return result
    }
    
    func detailedDescription() -> String {
        guard !isEmpty else { return "📦 Leeres Inventar" }
        
        var result = "📦 === Detailliertes Inventar ===\n"
        result += "Plätze verwendet: \(usedSlots)/\(maxCapacity)\n"
        result += "Gegenstände insgesamt: \(count)\n\n"
        
        for (index, slot) in items.enumerated() {
            let quantityText = slot.quantity > 1 ? " x\(slot.quantity)" : ""
            result += "\(index + 1). \(slot.item.description)\(quantityText)\n"
        }
        
        return result
    }
}

// MARK: - Inventory Slot

private struct InventorySlot {
    var item: Item
    var quantity: Int
    
    init(item: Item, quantity: Int = 1) {
        self.item = item
        self.quantity = quantity
    }
}

// MARK: - Inventory Statistics

struct InventoryStatistics {
    let totalItems: Int
    let usedSlots: Int
    let availableSlots: Int
    let typeDistribution: [ItemType: Int]
    let rarityDistribution: [ItemRarity: Int]
    let estimatedValue: Int
    
    var description: String {
        var result = "📊 === Inventar-Statistiken ===\n"
        result += "Gegenstände: \(totalItems)\n"
        result += "Plätze: \(usedSlots)/\(usedSlots + availableSlots)\n"
        result += "Geschätzter Wert: \(estimatedValue) Gold\n\n"
        
        result += "📦 Nach Typ:\n"
        for (type, count) in typeDistribution.sorted(by: { $0.key.description < $1.key.description }) {
            result += "  \(type.emoji) \(type.description): \(count)\n"
        }
        
        result += "\n🌟 Nach Seltenheit:\n"
        for (rarity, count) in rarityDistribution.sorted(by: { $0.key.description < $1.key.description }) {
            result += "  \(rarity.icon) \(rarity.description): \(count)\n"
        }
        
        return result
    }
}