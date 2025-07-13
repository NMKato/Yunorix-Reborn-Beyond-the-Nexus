//
//  PlayerNode.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import SceneKit
import Foundation

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - Player Control System

@MainActor
class PlayerNode: ObservableObject {
    
    // MARK: - Player Properties
    
    @Published var currentHero: SceneKitHero?
    @Published var isMoving: Bool = false
    @Published var moveSpeed: Double = 3.0
    @Published var rotationSpeed: Double = 2.0
    
    // MARK: - Control State
    
    @Published var selectedTarget: SceneKitCharacter?
    @Published var actionQueue: [PlayerAction] = []
    @Published var isInCombat: Bool = false
    
    // MARK: - Animation State
    
    private var currentAnimation: SCNAction?
    private var animationQueue: [SCNAction] = []
    private var isAnimating: Bool = false
    
    // MARK: - Movement
    
    func moveHero(to position: SCNVector3, completion: @escaping () -> Void = {}) {
        guard let hero = currentHero, !isMoving else { return }
        
        isMoving = true
        
        // Calculate movement direction and rotation
        let currentPos = hero.worldPosition
        let direction = SCNVector3(
            position.x - currentPos.x,
            0,
            position.z - currentPos.z
        )
        
        // Rotate hero to face movement direction
        if simd_length(simd_float3(direction)) > 0.1 {
            let angle = atan2(direction.x, direction.z)
            let rotateAction = SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.2)
            hero.node.runAction(rotateAction)
        }
        
        // Perform movement
        hero.moveTo(position: position) { [weak self] in
            self?.isMoving = false
            completion()
        }
        
        // Add walking animation
        playWalkAnimation()
    }
    
    func stopMovement() {
        guard let hero = currentHero else { return }
        
        hero.node.removeAllActions()
        isMoving = false
        stopWalkAnimation()
    }
    
    // MARK: - Combat Actions
    
    func attackTarget(_ target: SceneKitCharacter) {
        guard let hero = currentHero, !isInCombat else { return }
        
        isInCombat = true
        selectedTarget = target
        
        // Move closer if needed
        let distance = simd_distance(simd_float3(hero.worldPosition), simd_float3(target.worldPosition))
        if distance > 2.0 {
            let attackPosition = calculateAttackPosition(target: target)
            moveHero(to: attackPosition) { [weak self] in
                self?.executeAttack(on: target)
            }
        } else {
            executeAttack(on: target)
        }
    }
    
    private func executeAttack(on target: SceneKitCharacter) {
        guard let hero = currentHero else { return }
        
        // Face target
        let targetDirection = SCNVector3(
            target.worldPosition.x - hero.worldPosition.x,
            0,
            target.worldPosition.z - hero.worldPosition.z
        )
        
        let angle = atan2(targetDirection.x, targetDirection.z)
        let rotateAction = SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.1)
        
        hero.node.runAction(rotateAction) { [weak self] in
            self?.performAttackAnimation(on: target)
        }
    }
    
    private func performAttackAnimation(on target: SceneKitCharacter) {
        guard let hero = currentHero else { return }
        
        hero.playAttackAnimation(target: target)
        
        // Execute actual damage after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.dealDamage(to: target)
        }
    }
    
    private func dealDamage(to target: SceneKitCharacter) {
        guard let hero = currentHero else { return }
        
        // Calculate damage based on hero type
        var damage = hero.attackPower
        
        if let mage = hero as? SceneKitMage {
            damage += mage.spellPower
        }
        
        target.takeDamage(damage)
        
        // Check if target is defeated
        if target.isDefeated() {
            print("💀 \(target.name) defeated!")
        }
        
        // End combat turn
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isInCombat = false
            self?.selectedTarget = nil
        }
    }
    
    // MARK: - Special Abilities
    
    func castSpell(spellName: String, target: SceneKitCharacter? = nil) {
        guard let mage = currentHero as? SceneKitMage else { return }
        
        switch spellName {
        case "Heal":
            if let target = target {
                mage.heal(target: target, amount: 25)
            } else {
                mage.heal(target: mage, amount: 25)
            }
            
        case "Fireball":
            if let target = target {
                performSpellCast(caster: mage, target: target, spellType: .fire)
            }
            
        case "Meteor":
            // Area attack
            let targets = getNearbyEnemies()
            mage.areaAttack(targets: targets, damage: mage.spellPower * 2.0)
            
        default:
            print("Unknown spell: \(spellName)")
        }
    }
    
    private func performSpellCast(caster: SceneKitMage, target: SceneKitCharacter, spellType: SpellType) {
        // Face target
        let direction = SCNVector3(
            target.worldPosition.x - caster.worldPosition.x,
            0,
            target.worldPosition.z - caster.worldPosition.z
        )
        
        let angle = atan2(direction.x, direction.z)
        let rotateAction = SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.2)
        
        caster.node.runAction(rotateAction) { [weak self] in
            self?.createSpellProjectile(from: caster, to: target, type: spellType)
        }
    }
    
    private func createSpellProjectile(from caster: SceneKitMage, to target: SceneKitCharacter, type: SpellType) {
        let projectileGeometry = SCNSphere(radius: 0.1)
        
        switch type {
        case .fire:
            #if os(macOS)
            projectileGeometry.firstMaterial?.diffuse.contents = NSColor.red
            projectileGeometry.firstMaterial?.emission.contents = NSColor.orange
            #else
            projectileGeometry.firstMaterial?.diffuse.contents = UIColor.red
            projectileGeometry.firstMaterial?.emission.contents = UIColor.orange
            #endif
        case .ice:
            #if os(macOS)
            projectileGeometry.firstMaterial?.diffuse.contents = NSColor.cyan
            projectileGeometry.firstMaterial?.emission.contents = NSColor.blue
            #else
            projectileGeometry.firstMaterial?.diffuse.contents = UIColor.cyan
            projectileGeometry.firstMaterial?.emission.contents = UIColor.blue
            #endif
        case .lightning:
            #if os(macOS)
            projectileGeometry.firstMaterial?.diffuse.contents = NSColor.yellow
            projectileGeometry.firstMaterial?.emission.contents = NSColor.white
            #else
            projectileGeometry.firstMaterial?.diffuse.contents = UIColor.yellow
            projectileGeometry.firstMaterial?.emission.contents = UIColor.white
            #endif
        }
        
        let projectile = SCNNode(geometry: projectileGeometry)
        projectile.position = caster.worldPosition
        
        caster.node.parent?.addChildNode(projectile)
        
        // Animate projectile to target
        let flyAction = SCNAction.move(to: target.worldPosition, duration: 0.5)
        let explodeAction = SCNAction.removeFromParentNode()
        
        projectile.runAction(SCNAction.sequence([flyAction, explodeAction])) { [weak self] in
            self?.applySpellDamage(to: target, type: type, caster: caster)
        }
    }
    
    private func applySpellDamage(to target: SceneKitCharacter, type: SpellType, caster: SceneKitMage) {
        let damage = caster.spellPower + caster.attackPower
        target.takeDamage(damage)
        
        // Apply status effects based on spell type
        switch type {
        case .fire:
            // Chance to burn
            if Double.random(in: 0...1) < 0.3 {
                target.applyStatus(.poisoned, duration: 3, intensity: 1.0) // Using poisoned as burn effect
            }
        case .ice:
            // Chance to freeze/slow
            if Double.random(in: 0...1) < 0.4 {
                target.applyStatus(.paralyzed, duration: 2, intensity: 1.0)
            }
        case .lightning:
            // Higher crit chance, already applied
            break
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateAttackPosition(target: SceneKitCharacter) -> SCNVector3 {
        let direction = simd_normalize(simd_float3(
            target.worldPosition.x - currentHero!.worldPosition.x,
            0,
            target.worldPosition.z - currentHero!.worldPosition.z
        ))
        
        let attackDistance: Float = 1.5
        let attackPosition = simd_float3(target.worldPosition) - direction * attackDistance
        
        return SCNVector3(attackPosition.x, 0, attackPosition.z)
    }
    
    private func getNearbyEnemies(radius: Double = 5.0) -> [Character] {
        guard let hero = currentHero else { return [] }
        
        // This would need to be implemented with the game scene
        // For now, return empty array
        return []
    }
    
    // MARK: - Animation System
    
    private func playWalkAnimation() {
        guard let hero = currentHero else { return }
        
        // Simple walking animation - bob up and down
        let bobUp = SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 0.3)
        let bobDown = SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 0.3)
        let walkCycle = SCNAction.sequence([bobUp, bobDown])
        let repeatWalk = SCNAction.repeatForever(walkCycle)
        
        hero.node.runAction(repeatWalk, forKey: "walkAnimation")
    }
    
    private func stopWalkAnimation() {
        guard let hero = currentHero else { return }
        hero.node.removeAction(forKey: "walkAnimation")
    }
    
    // MARK: - Hero Management
    
    func setHero(_ hero: SceneKitHero) {
        currentHero = hero
        resetControlState()
    }
    
    private func resetControlState() {
        isMoving = false
        isInCombat = false
        selectedTarget = nil
        actionQueue.removeAll()
        stopMovement()
    }
    
    // MARK: - Action Queue System
    
    func queueAction(_ action: PlayerAction) {
        actionQueue.append(action)
        processActionQueue()
    }
    
    private func processActionQueue() {
        guard !actionQueue.isEmpty, !isAnimating else { return }
        
        let action = actionQueue.removeFirst()
        executeAction(action)
    }
    
    private func executeAction(_ action: PlayerAction) {
        isAnimating = true
        
        switch action {
        case .move(let position):
            moveHero(to: position) { [weak self] in
                self?.isAnimating = false
                self?.processActionQueue()
            }
            
        case .attack(let target):
            attackTarget(target)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isAnimating = false
                self?.processActionQueue()
            }
            
        case .castSpell(let spellName, let target):
            castSpell(spellName: spellName, target: target)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.isAnimating = false
                self?.processActionQueue()
            }
            
        case .wait(let duration):
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.isAnimating = false
                self?.processActionQueue()
            }
        }
    }
}

// MARK: - Supporting Types

enum PlayerAction {
    case move(SCNVector3)
    case attack(SceneKitCharacter)
    case castSpell(String, SceneKitCharacter?)
    case wait(Double)
}

enum SpellType {
    case fire
    case ice
    case lightning
}