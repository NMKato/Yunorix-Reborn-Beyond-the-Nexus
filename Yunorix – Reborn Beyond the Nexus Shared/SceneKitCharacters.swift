//
//  SceneKitCharacters.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import SceneKit
import Foundation

#if os(macOS)
    import AppKit
    typealias SCNColor = NSColor
#else
    import UIKit
    typealias SCNColor = UIColor
#endif

// MARK: - 3D Character Base Class

@MainActor
class SceneKitCharacter: Character {
    
    // MARK: - 3D Properties
    
    var node: SCNNode
    var modelNode: SCNNode?
    var particleSystem: SCNParticleSystem?
    var animationQueue: [SCNAction] = []
    
    // MARK: - Position & Movement
    
    var worldPosition: SCNVector3 {
        get { return node.position }
        set { node.position = newValue }
    }
    
    var targetPosition: SCNVector3?
    var moveSpeed: Double = 2.0
    var isMoving: Bool = false
    
    // MARK: - Visual State
    
    var healthBarNode: SCNNode?
    var statusEffectNodes: [SCNNode] = []
    var selectionIndicator: SCNNode?
    var isSelected: Bool = false
    
    // MARK: - Audio
    
    var audioSource: SCNAudioSource?
    var attackSounds: [String: SCNAudioSource] = [:]
    
    // MARK: - Initialization
    
    init(name: String, maxHP: Double, attack: Double, defense: Double, modelName: String?) {
        
        // Create base node
        self.node = SCNNode()
        self.node.name = name
        
        super.init(name: name, maxHP: maxHP, attack: attack, defense: defense)
        
        setupModel(modelName: modelName)
        setupHealthBar()
        setupSelectionIndicator()
        setupAudio()
    }
    
    // MARK: - 3D Setup
    
    private func setupModel(modelName: String?) {
        if let modelName = modelName,
           let scene = SCNScene(named: "Art.scnassets/\(modelName).scn"),
           let model = scene.rootNode.childNodes.first {
            modelNode = model.clone()
            node.addChildNode(modelNode!)
        } else {
            // Fallback to basic geometry
            let geometry = SCNBox(width: 1, height: 2, length: 1, chamferRadius: 0.1)
            modelNode = SCNNode(geometry: geometry)
            
            // Color based on character type
            geometry.firstMaterial?.diffuse.contents = SCNColor.blue
            
            node.addChildNode(modelNode!)
        }
    }
    
    private func setupHealthBar() {
        // Background
        let bgGeometry = SCNPlane(width: 1.2, height: 0.2)
        bgGeometry.firstMaterial?.diffuse.contents = SCNColor.black
        
        let bgNode = SCNNode(geometry: bgGeometry)
        bgNode.position = SCNVector3(0, 1.5, 0)
        bgNode.name = "healthBarBG"
        
        // Health bar
        let healthGeometry = SCNPlane(width: 1.0, height: 0.15)
        healthGeometry.firstMaterial?.diffuse.contents = SCNColor.green
        
        healthBarNode = SCNNode(geometry: healthGeometry)
        healthBarNode?.position = SCNVector3(0, 1.5, 0.01)
        healthBarNode?.name = "healthBar"
        
        node.addChildNode(bgNode)
        node.addChildNode(healthBarNode!)
        
        // Name label
        let text = SCNText(string: name, extrusionDepth: 0.1)
        #if os(macOS)
        text.font = NSFont.systemFont(ofSize: 0.3)
        #else
        text.font = UIFont.systemFont(ofSize: 0.3)
        #endif
        text.firstMaterial?.diffuse.contents = SCNColor.white
        
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3(-0.5, 2, 0)
        textNode.scale = SCNVector3(0.5, 0.5, 0.5)
        textNode.name = "nameLabel"
        
        node.addChildNode(textNode)
    }
    
    private func setupSelectionIndicator() {
        let ring = SCNTorus(ringRadius: 1.5, pipeRadius: 0.1)
        ring.firstMaterial?.diffuse.contents = SCNColor.yellow
        ring.firstMaterial?.emission.contents = SCNColor.yellow
        
        selectionIndicator = SCNNode(geometry: ring)
        selectionIndicator?.position = SCNVector3(0, 0.1, 0)
        selectionIndicator?.eulerAngles = SCNVector3(-Double.pi/2, 0, 0)
        selectionIndicator?.isHidden = true
        
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 0.5),
            SCNAction.scale(to: 1.0, duration: 0.5)
        ])
        let repeatPulse = SCNAction.repeatForever(pulse)
        selectionIndicator?.runAction(repeatPulse)
        
        node.addChildNode(selectionIndicator!)
    }
    
    private func setupAudio() {
        // Default attack sound
        if let soundURL = Bundle.main.url(forResource: "attack_default", withExtension: "mp3") {
            audioSource = SCNAudioSource(url: soundURL)
            audioSource?.volume = 0.5
        }
    }
    
    // MARK: - Visual Updates
    
    override func takeDamage(_ amount: Double) {
        super.takeDamage(amount)
        updateHealthBar()
        playDamageAnimation()
    }
    
    override func heal(_ amount: Double) {
        super.heal(amount)
        updateHealthBar()
        playHealAnimation()
    }
    
    private func updateHealthBar() {
        guard let healthBar = healthBarNode,
              let geometry = healthBar.geometry as? SCNPlane else { return }
        
        let healthPercentage = healthPercentage()
        let newWidth = 1.0 * healthPercentage
        
        geometry.width = CGFloat(newWidth)
        
        // Update color based on health
        let healthColor: SCNColor
        if healthPercentage > 0.6 {
            healthColor = SCNColor.green
        } else if healthPercentage > 0.3 {
            healthColor = SCNColor.yellow
        } else {
            healthColor = SCNColor.red
        }
        
        geometry.firstMaterial?.diffuse.contents = healthColor
    }
    
    // MARK: - Animation System
    
    func playAttackAnimation(target: SceneKitCharacter) {
        guard let modelNode = modelNode else { return }
        
        let originalPosition = node.position
        let targetPos = target.node.position
        
        // Move towards target
        let moveForward = SCNAction.move(to: targetPos, duration: 0.3)
        let moveBack = SCNAction.move(to: originalPosition, duration: 0.3)
        
        // Attack animation
        let attackRotation = SCNAction.rotateBy(x: 0, y: Double.pi * 2, z: 0, duration: 0.2)
        
        let attackSequence = SCNAction.sequence([
            moveForward,
            attackRotation,
            moveBack
        ])
        
        node.runAction(attackSequence)
        
        // Play attack sound
        if let audioSource = audioSource {
            node.runAction(SCNAction.playAudio(audioSource, waitForCompletion: false))
        }
    }
    
    private func playDamageAnimation() {
        guard let modelNode = modelNode else { return }
        
        // Flash red when taking damage
        let originalColor = modelNode.geometry?.firstMaterial?.diffuse.contents
        
        let flashRed = SCNAction.customAction(duration: 0.1) { node, _ in
            node.geometry?.firstMaterial?.diffuse.contents = SCNColor.red
        }
        
        let flashWhite = SCNAction.customAction(duration: 0.1) { node, _ in
            node.geometry?.firstMaterial?.diffuse.contents = SCNColor.white
        }
        
        let restore = SCNAction.customAction(duration: 0.1) { node, _ in
            node.geometry?.firstMaterial?.diffuse.contents = originalColor
        }
        
        let damageSequence = SCNAction.sequence([flashRed, flashWhite, restore])
        modelNode.runAction(damageSequence)
        
        // Shake effect
        let shake = SCNAction.sequence([
            SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.05),
            SCNAction.moveBy(x: -0.2, y: 0, z: 0, duration: 0.05),
            SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.05)
        ])
        
        node.runAction(shake)
    }
    
    private func playHealAnimation() {
        // Green healing sparkles
        let sparkleGeometry = SCNSphere(radius: 0.05)
        sparkleGeometry.firstMaterial?.diffuse.contents = SCNColor.green
        sparkleGeometry.firstMaterial?.emission.contents = SCNColor.green
        
        for i in 0..<5 {
            let sparkle = SCNNode(geometry: sparkleGeometry)
            sparkle.position = SCNVector3(
                Double.random(in: -0.5...0.5),
                Double.random(in: 0.5...2.0),
                Double.random(in: -0.5...0.5)
            )
            
            node.addChildNode(sparkle)
            
            let floatUp = SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 1.0)
            let fadeOut = SCNAction.fadeOut(duration: 1.0)
            let remove = SCNAction.removeFromParentNode()
            
            let sequence = SCNAction.sequence([
                SCNAction.group([floatUp, fadeOut]),
                remove
            ])
            
            sparkle.runAction(sequence)
        }
    }
    
    // MARK: - Status Effect Visuals
    
    override func applyStatus(_ status: CharacterStatus, duration: Int, intensity: Double) {
        super.applyStatus(status, duration: duration, intensity: intensity)
        addStatusEffectVisual(status)
    }
    
    override func removeStatus(_ status: CharacterStatus) {
        super.removeStatus(status)
        removeStatusEffectVisual(status)
    }
    
    private func addStatusEffectVisual(_ status: CharacterStatus) {
        // Remove existing visual for this status
        removeStatusEffectVisual(status)
        
        let effectNode = SCNNode()
        effectNode.name = "effect_\(status)"
        
        switch status {
        case .poisoned:
            let poisonGeometry = SCNSphere(radius: 0.1)
            poisonGeometry.firstMaterial?.diffuse.contents = SCNColor.green
            poisonGeometry.firstMaterial?.emission.contents = SCNColor.green
            effectNode.geometry = poisonGeometry
            effectNode.position = SCNVector3(0, 1, 0)
            
            let bob = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 1.0),
                SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 1.0)
            ])
            effectNode.runAction(SCNAction.repeatForever(bob))
            
        case .cursed:
            let curseGeometry = SCNTorus(ringRadius: 0.3, pipeRadius: 0.05)
            curseGeometry.firstMaterial?.diffuse.contents = SCNColor.purple
            curseGeometry.firstMaterial?.emission.contents = SCNColor.purple
            effectNode.geometry = curseGeometry
            effectNode.position = SCNVector3(0, 1.2, 0)
            
            let spin = SCNAction.rotateBy(x: 0, y: Double.pi * 2, z: 0, duration: 2.0)
            effectNode.runAction(SCNAction.repeatForever(spin))
            
        case .paralyzed:
            let sparkGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            sparkGeometry.firstMaterial?.diffuse.contents = SCNColor.yellow
            sparkGeometry.firstMaterial?.emission.contents = SCNColor.yellow
            effectNode.geometry = sparkGeometry
            effectNode.position = SCNVector3(0, 1.5, 0)
            
            let flash = SCNAction.sequence([
                SCNAction.fadeOut(duration: 0.2),
                SCNAction.fadeIn(duration: 0.2)
            ])
            effectNode.runAction(SCNAction.repeatForever(flash))
            
        default:
            break
        }
        
        if effectNode.geometry != nil {
            statusEffectNodes.append(effectNode)
            node.addChildNode(effectNode)
        }
    }
    
    private func removeStatusEffectVisual(_ status: CharacterStatus) {
        statusEffectNodes.removeAll { effectNode in
            if effectNode.name == "effect_\(status)" {
                effectNode.removeFromParentNode()
                return true
            }
            return false
        }
    }
    
    // MARK: - Selection
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        selectionIndicator?.isHidden = !selected
    }
    
    // MARK: - Movement
    
    func moveTo(position: SCNVector3, completion: @escaping () -> Void = {}) {
        guard !isMoving else { return }
        
        isMoving = true
        targetPosition = position
        
        let distance = simd_distance(simd_float3(node.position), simd_float3(position))
        let duration = TimeInterval(distance / Float(moveSpeed))
        
        let moveAction = SCNAction.move(to: position, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        
        node.runAction(moveAction) { [weak self] in
            self?.isMoving = false
            self?.targetPosition = nil
            completion()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        node.removeFromParentNode()
        statusEffectNodes.forEach { $0.removeFromParentNode() }
    }
}

// MARK: - 3D Hero Class

@MainActor
class SceneKitHero: SceneKitCharacter {
    
    override init(name: String, maxHP: Double, attack: Double, defense: Double, modelName: String? = nil) {
        super.init(name: name, maxHP: maxHP, attack: attack, defense: defense, modelName: modelName)
        
        // Hero-specific visual setup
        if let geometry = modelNode?.geometry {
            geometry.firstMaterial?.diffuse.contents = SCNColor.blue
            geometry.firstMaterial?.specular.contents = SCNColor.white
            geometry.firstMaterial?.shininess = 0.8
        }
        
        // Add hero glow
        let glowGeometry = SCNSphere(radius: 1.2)
        glowGeometry.firstMaterial?.diffuse.contents = SCNColor.blue.withAlphaComponent(0.2)
        glowGeometry.firstMaterial?.emission.contents = SCNColor.blue.withAlphaComponent(0.1)
        
        let glowNode = SCNNode(geometry: glowGeometry)
        glowNode.name = "heroGlow"
        node.addChildNode(glowNode)
        
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 2.0),
            SCNAction.scale(to: 1.0, duration: 2.0)
        ])
        glowNode.runAction(SCNAction.repeatForever(breathe))
    }
}

// MARK: - 3D Enemy Class

@MainActor
class SceneKitEnemy: SceneKitCharacter {
    
    var aiDifficulty: AIDifficulty
    var threatLevel: Double = 1.0
    
    init(name: String, maxHP: Double, attack: Double, defense: Double, difficulty: AIDifficulty, modelName: String? = nil) {
        self.aiDifficulty = difficulty
        super.init(name: name, maxHP: maxHP, attack: attack, defense: defense, modelName: modelName)
        
        // Enemy-specific visual setup
        if let geometry = modelNode?.geometry {
            geometry.firstMaterial?.diffuse.contents = SCNColor.red
            geometry.firstMaterial?.emission.contents = SCNColor.red.withAlphaComponent(0.3)
        }
        
        // Add menacing red glow
        let glowGeometry = SCNSphere(radius: 1.3)
        glowGeometry.firstMaterial?.diffuse.contents = SCNColor.red.withAlphaComponent(0.2)
        glowGeometry.firstMaterial?.emission.contents = SCNColor.red.withAlphaComponent(0.2)
        
        let glowNode = SCNNode(geometry: glowGeometry)
        glowNode.name = "enemyGlow"
        node.addChildNode(glowNode)
        
        // Pulsing menacing effect
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 1.0),
            SCNAction.scale(to: 1.0, duration: 1.0)
        ])
        glowNode.runAction(SCNAction.repeatForever(pulse))
        
        setupThreatIndicator()
    }
    
    private func setupThreatIndicator() {
        let skullGeometry = SCNBox(width: 0.2, height: 0.2, length: 0.1, chamferRadius: 0.05)
        skullGeometry.firstMaterial?.diffuse.contents = SCNColor.darkGray
        
        let skullNode = SCNNode(geometry: skullGeometry)
        skullNode.position = SCNVector3(0, 2.2, 0)
        skullNode.name = "threatIndicator"
        
        let float = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 1.5),
            SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: 1.5)
        ])
        skullNode.runAction(SCNAction.repeatForever(float))
        
        node.addChildNode(skullNode)
    }
}

// MARK: - Specialized Hero Classes

@MainActor
class SceneKitMage: SceneKitHero {
    
    var spellPower: Double
    var manaBarNode: SCNNode?
    
    // Use inherited mana properties from Character base class
    
    init(name: String) {
        self.spellPower = 15
        
        super.init(name: name, maxHP: 80, attack: 12, defense: 5, modelName: "mage")
        
        // Set mana after super.init
        self.maxManaPoints = 100
        self.manaPoints = 100
        
        setupManaBar()
        addMagicalEffects()
    }
    
    // MARK: - Mana Management
    
    func consumeMana(_ amount: Double) -> Bool {
        guard currentMana >= amount else { return false }
        currentMana -= amount
        updateManaBar()
        return true
    }
    
    func regenerateMana(_ amount: Double) {
        currentMana = min(currentMana + amount, maxMana)
        updateManaBar()
    }
    
    func hasEnoughMana(_ requiredMana: Double) -> Bool {
        return currentMana >= requiredMana
    }
    
    private func updateManaBar() {
        guard let manaBar = manaBarNode,
              let geometry = manaBar.geometry as? SCNPlane else { return }
        
        let manaPercentage = currentMana / maxMana
        let newWidth = 1.0 * manaPercentage
        geometry.width = CGFloat(newWidth)
    }
    
    private func setupManaBar() {
        let manaGeometry = SCNPlane(width: 1.0, height: 0.1)
        manaGeometry.firstMaterial?.diffuse.contents = SCNColor.blue
        
        manaBarNode = SCNNode(geometry: manaGeometry)
        manaBarNode?.position = SCNVector3(0, 1.3, 0.01)
        manaBarNode?.name = "manaBar"
        
        node.addChildNode(manaBarNode!)
    }
    
    private func addMagicalEffects() {
        // Floating magical orbs
        for i in 0..<3 {
            let orbGeometry = SCNSphere(radius: 0.08)
            orbGeometry.firstMaterial?.diffuse.contents = SCNColor.cyan
            orbGeometry.firstMaterial?.emission.contents = SCNColor.cyan
            
            let orb = SCNNode(geometry: orbGeometry)
            let angle = Double(i) * (Double.pi * 2 / 3)
            orb.position = SCNVector3(
                cos(angle) * 0.8,
                1.8,
                sin(angle) * 0.8
            )
            
            let orbit = SCNAction.rotateBy(x: 0, y: Double.pi * 2, z: 0, duration: 3.0)
            orb.runAction(SCNAction.repeatForever(orbit))
            
            node.addChildNode(orb)
        }
    }
    
    func areaAttack(targets: [Character], damage: Double) {
        // Visual meteor effect
        let meteorGeometry = SCNSphere(radius: 0.3)
        meteorGeometry.firstMaterial?.diffuse.contents = SCNColor.orange
        meteorGeometry.firstMaterial?.emission.contents = SCNColor.red
        
        let meteor = SCNNode(geometry: meteorGeometry)
        meteor.position = SCNVector3(0, 10, 0)
        
        node.parent?.addChildNode(meteor)
        
        let fall = SCNAction.move(to: SCNVector3(0, 0, 0), duration: 1.0)
        let explode = SCNAction.removeFromParentNode()
        
        meteor.runAction(SCNAction.sequence([fall, explode]))
    }
    
    func heal(target: Character, amount: Double) {
        // Healing beam effect
        if let targetCharacter = target as? SceneKitCharacter {
            let startPos = node.position
            let endPos = targetCharacter.node.position
            
            // Create healing beam
            let distance = simd_distance(simd_float3(startPos), simd_float3(endPos))
            let beamGeometry = SCNCylinder(radius: 0.05, height: CGFloat(distance))
            beamGeometry.firstMaterial?.diffuse.contents = SCNColor.green
            beamGeometry.firstMaterial?.emission.contents = SCNColor.green
            
            let beam = SCNNode(geometry: beamGeometry)
            beam.position = SCNVector3(
                (startPos.x + endPos.x) / 2,
                (startPos.y + endPos.y) / 2,
                (startPos.z + endPos.z) / 2
            )
            
            node.parent?.addChildNode(beam)
            
            let fadeOut = SCNAction.fadeOut(duration: 0.5)
            let remove = SCNAction.removeFromParentNode()
            beam.runAction(SCNAction.sequence([fadeOut, remove]))
        }
    }
    
    func canHeal(target: Character) -> Bool {
        return !target.isDefeated() && hasEnoughMana(25)
    }
}

@MainActor
class SceneKitWarrior: SceneKitHero {
    
    @Published var shield: Double
    @Published var maxShield: Double
    @Published var rage: Double = 0
    @Published var maxRage: Double = 100
    var isRaging: Bool = false
    var resistances: [CharacterStatus] = [.paralyzed, .cursed]
    var shieldNode: SCNNode?
    
    init(name: String) {
        self.maxShield = 30
        self.shield = 30
        
        super.init(name: name, maxHP: 120, attack: 18, defense: 12, modelName: "warrior")
        
        setupShieldVisual()
        addWarriorEffects()
    }
    
    private func setupShieldVisual() {
        let shieldGeometry = SCNTorus(ringRadius: 0.8, pipeRadius: 0.1)
        shieldGeometry.firstMaterial?.diffuse.contents = SCNColor.lightGray
        shieldGeometry.firstMaterial?.metalness.contents = 0.8
        shieldGeometry.firstMaterial?.roughness.contents = 0.2
        
        shieldNode = SCNNode(geometry: shieldGeometry)
        shieldNode?.position = SCNVector3(0, 1, 0)
        shieldNode?.name = "shieldEffect"
        
        let spin = SCNAction.rotateBy(x: 0, y: 0, z: Double.pi * 2, duration: 2.0)
        shieldNode?.runAction(SCNAction.repeatForever(spin))
        
        node.addChildNode(shieldNode!)
    }
    
    private func addWarriorEffects() {
        // Battle aura when raging
        let auraGeometry = SCNSphere(radius: 1.5)
        auraGeometry.firstMaterial?.diffuse.contents = SCNColor.red.withAlphaComponent(0.3)
        auraGeometry.firstMaterial?.emission.contents = SCNColor.red.withAlphaComponent(0.5)
        
        let auraNode = SCNNode(geometry: auraGeometry)
        auraNode.name = "rageAura"
        auraNode.isHidden = true
        
        node.addChildNode(auraNode)
    }
    
    override func defend() {
        super.defend()
        
        // Shield glow effect
        shieldNode?.runAction(SCNAction.sequence([
            SCNAction.scale(to: 1.3, duration: 0.2),
            SCNAction.scale(to: 1.0, duration: 0.2)
        ]))
    }
    
    func activateRage() {
        isRaging = true
        
        if let auraNode = node.childNode(withName: "rageAura", recursively: false) {
            auraNode.isHidden = false
            
            let pulse = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 0.5),
                SCNAction.scale(to: 1.0, duration: 0.5)
            ])
            auraNode.runAction(SCNAction.repeatForever(pulse))
        }
    }
}

@MainActor
class SceneKitRogue: SceneKitHero {
    
    @Published var stealth: Bool = false
    @Published var stealthDuration: Int = 0
    var agility: Double
    var availableStatusEffects: [CharacterStatus] = [.poisoned, .paralyzed]
    var resistances: [CharacterStatus] = []
    
    init(name: String) {
        self.agility = 18
        
        super.init(name: name, maxHP: 90, attack: 15, defense: 8, modelName: "rogue")
        
        criticalChance = 0.25
        addRogueEffects()
    }
    
    private func addRogueEffects() {
        // Shadow trail effect
        let shadowGeometry = SCNPlane(width: 0.8, height: 1.8)
        shadowGeometry.firstMaterial?.diffuse.contents = SCNColor.black.withAlphaComponent(0.5)
        
        let shadowNode = SCNNode(geometry: shadowGeometry)
        shadowNode.position = SCNVector3(0, 0, -0.1)
        shadowNode.name = "shadowTrail"
        shadowNode.isHidden = true
        
        node.addChildNode(shadowNode)
    }
    
    func enterStealth() {
        stealth = true
        stealthDuration = 3
        
        // Fade character
        let fadeOut = SCNAction.fadeOpacity(to: 0.3, duration: 0.5)
        node.runAction(fadeOut)
        
        // Show shadow trail
        if let shadowNode = node.childNode(withName: "shadowTrail", recursively: false) {
            shadowNode.isHidden = false
        }
    }
    
    func exitStealth() {
        stealth = false
        stealthDuration = 0
        
        // Restore visibility
        let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
        node.runAction(fadeIn)
        
        // Hide shadow trail
        if let shadowNode = node.childNode(withName: "shadowTrail", recursively: false) {
            shadowNode.isHidden = true
        }
    }
    
    func applyStatusEffect(_ effect: CharacterStatus, to target: Character, duration: Int?) {
        guard availableStatusEffects.contains(effect) else { return }
        
        target.applyStatus(effect, duration: duration ?? 3)
        
        // Visual poison dart or paralysis effect
        if let targetCharacter = target as? SceneKitCharacter {
            createStatusProjectile(effect: effect, target: targetCharacter)
        }
    }
    
    private func createStatusProjectile(effect: CharacterStatus, target: SceneKitCharacter) {
        let projectileGeometry = SCNSphere(radius: 0.05)
        
        switch effect {
        case .poisoned:
            projectileGeometry.firstMaterial?.diffuse.contents = SCNColor.green
        case .paralyzed:
            projectileGeometry.firstMaterial?.diffuse.contents = SCNColor.yellow
        default:
            projectileGeometry.firstMaterial?.diffuse.contents = SCNColor.purple
        }
        
        let projectile = SCNNode(geometry: projectileGeometry)
        projectile.position = node.position
        
        node.parent?.addChildNode(projectile)
        
        let fly = SCNAction.move(to: target.node.position, duration: 0.3)
        let explode = SCNAction.removeFromParentNode()
        
        projectile.runAction(SCNAction.sequence([fly, explode]))
    }
}
