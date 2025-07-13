//
//  GameController.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by 4Gi .tv on 12.07.25.
//

import SceneKit
import Foundation

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

@MainActor
class GameController: NSObject, ObservableObject, SCNSceneRendererDelegate {

    // MARK: - Scene Properties
    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer
    
    // MARK: - RPG System
    let combatManager: CombatManager
    var currentHeroes: [Hero] = []
    var encounterEnemies: [Enemy] = []
    
    // MARK: - Scene Nodes
    private var heroNodes: [SCNNode] = []
    private var enemyNodes: [SCNNode] = []
    private var battleArena: SCNNode?
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        scene = SCNScene(named: "Art.scnassets/ship.scn")!
        combatManager = CombatManager()
        
        super.init()
        
        sceneRenderer.delegate = self
        setupInitialScene()
        setupRPGSystem()
        
        sceneRenderer.scene = scene
    }
    
    // MARK: - Scene Setup
    
    private func setupInitialScene() {
        if let ship = scene.rootNode.childNode(withName: "ship", recursively: true) {
            ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        }
        
        setupLighting()
        setupBattleArena()
    }
    
    private func setupLighting() {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = PlatformColor.gray
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    private func setupBattleArena() {
        battleArena = SCNNode()
        battleArena?.position = SCNVector3(x: 0, y: -2, z: 0)
        
        let floor = SCNPlane(width: 20, height: 20)
        floor.firstMaterial?.diffuse.contents = PlatformColor.darkGray
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        battleArena?.addChildNode(floorNode)
        
        scene.rootNode.addChildNode(battleArena!)
    }
    
    // MARK: - RPG System Setup
    
    private func setupRPGSystem() {
        currentHeroes = [
            Mage(name: "Aeliana"),
            Warrior(name: "Gareth"),
            Rogue(name: "Zara")
        ]
        
        for hero in currentHeroes {
            hero.inventory.addItem(ItemFactory.healingItems[0])
            hero.inventory.addItem(ItemFactory.healingItems[1])
        }
        
        createHeroNodes()
    }
    
    private func createHeroNodes() {
        heroNodes.removeAll()
        
        for (index, hero) in currentHeroes.enumerated() {
            let heroNode = createCharacterNode(for: hero, position: getHeroPosition(index))
            heroNodes.append(heroNode)
            scene.rootNode.addChildNode(heroNode)
        }
    }
    
    private func createEnemyNodes() {
        enemyNodes.forEach { $0.removeFromParentNode() }
        enemyNodes.removeAll()
        
        for (index, enemy) in encounterEnemies.enumerated() {
            let enemyNode = createCharacterNode(for: enemy, position: getEnemyPosition(index))
            enemyNodes.append(enemyNode)
            scene.rootNode.addChildNode(enemyNode)
        }
    }
    
    private func createCharacterNode(for character: Character, position: SCNVector3) -> SCNNode {
        let characterNode = SCNNode()
        
        let geometry = SCNBox(width: 1, height: 2, length: 1, chamferRadius: 0.1)
        
        if character is Hero {
            geometry.firstMaterial?.diffuse.contents = PlatformColor.blue
        } else {
            geometry.firstMaterial?.diffuse.contents = PlatformColor.red
        }
        
        characterNode.geometry = geometry
        characterNode.position = position
        characterNode.name = character.name
        
        addHealthBar(to: characterNode, character: character)
        addCharacterLabel(to: characterNode, character: character)
        
        return characterNode
    }
    
    private func addHealthBar(to node: SCNNode, character: Character) {
        let healthBarBG = SCNPlane(width: 1.2, height: 0.2)
        healthBarBG.firstMaterial?.diffuse.contents = PlatformColor.black
        
        let healthBarBGNode = SCNNode(geometry: healthBarBG)
        healthBarBGNode.position = SCNVector3(0, 1.5, 0)
        healthBarBGNode.name = "healthBarBG"
        
        let healthBar = SCNPlane(width: 1.0, height: 0.15)
        healthBar.firstMaterial?.diffuse.contents = PlatformColor.green
        
        let healthBarNode = SCNNode(geometry: healthBar)
        healthBarNode.position = SCNVector3(0, 1.5, 0.01)
        healthBarNode.name = "healthBar"
        
        node.addChildNode(healthBarBGNode)
        node.addChildNode(healthBarNode)
        
        updateHealthBar(for: node, character: character)
    }
    
    private func addCharacterLabel(to node: SCNNode, character: Character) {
        let text = SCNText(string: character.name, extrusionDepth: 0.1)
        #if os(macOS)
        text.font = NSFont.systemFont(ofSize: 0.3)
        #else
        text.font = UIFont.systemFont(ofSize: 0.3)
        #endif
        text.firstMaterial?.diffuse.contents = PlatformColor.white
        
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3(-0.5, 2, 0)
        textNode.scale = SCNVector3(0.5, 0.5, 0.5)
        textNode.name = "nameLabel"
        
        node.addChildNode(textNode)
    }
    
    // MARK: - Position Helpers
    
    private func getHeroPosition(_ index: Int) -> SCNVector3 {
        let spacing: Float = 3.0
        let startX: Float = -Float(currentHeroes.count - 1) * spacing / 2
        return SCNVector3(startX + Float(index) * spacing, 0, -5)
    }
    
    private func getEnemyPosition(_ index: Int) -> SCNVector3 {
        let spacing: Float = 3.0
        let startX: Float = -Float(encounterEnemies.count - 1) * spacing / 2
        return SCNVector3(startX + Float(index) * spacing, 0, 5)
    }
    
    // MARK: - Combat System Integration
    
    func startRandomEncounter() {
        encounterEnemies = generateRandomEnemies()
        createEnemyNodes()
        combatManager.startCombat(heroes: currentHeroes, enemies: encounterEnemies)
    }
    
    func startBossFight() {
        encounterEnemies = [FinalBoss()]
        createEnemyNodes()
        combatManager.startCombat(heroes: currentHeroes, enemies: encounterEnemies)
    }
    
    private func generateRandomEnemies() -> [Enemy] {
        let enemyTypes: [() -> Enemy] = [
            { Skeleton() },
            { Orc() },
            { Dragon() }
        ]
        
        let count = Int.random(in: 1...3)
        var enemies: [Enemy] = []
        
        for _ in 0..<count {
            let enemyFactory = enemyTypes.randomElement()!
            enemies.append(enemyFactory())
        }
        
        return enemies
    }
    
    // MARK: - Visual Updates
    
    private func updateHealthBar(for node: SCNNode, character: Character) {
        guard let healthBar = node.childNode(withName: "healthBar", recursively: false) else { return }
        guard let healthBarGeometry = healthBar.geometry as? SCNPlane else { return }
        
        let healthPercentage = character.healthPercentage()
        let newWidth = 1.0 * healthPercentage
        
        healthBarGeometry.width = CGFloat(newWidth)
        
        let healthColor: PlatformColor
        if healthPercentage > 0.6 {
            healthColor = PlatformColor.green
        } else if healthPercentage > 0.3 {
            healthColor = PlatformColor.yellow
        } else {
            healthColor = PlatformColor.red
        }
        
        healthBarGeometry.firstMaterial?.diffuse.contents = healthColor
    }
    
    private func updateAllHealthBars() {
        for (index, hero) in currentHeroes.enumerated() {
            if index < heroNodes.count {
                updateHealthBar(for: heroNodes[index], character: hero)
            }
        }
        
        for (index, enemy) in encounterEnemies.enumerated() {
            if index < enemyNodes.count {
                updateHealthBar(for: enemyNodes[index], character: enemy)
            }
        }
    }
    
    private func animateAttack(attacker: SCNNode, target: SCNNode) {
        let originalPosition = attacker.position
        let targetPosition = target.position
        
        let moveToTarget = SCNAction.move(to: targetPosition, duration: 0.3)
        let moveBack = SCNAction.move(to: originalPosition, duration: 0.3)
        let sequence = SCNAction.sequence([moveToTarget, moveBack])
        
        attacker.runAction(sequence)
        
        let flash = SCNAction.customAction(duration: 0.1) { node, _ in
            node.geometry?.firstMaterial?.emission.contents = PlatformColor.white
        }
        
        let unflash = SCNAction.customAction(duration: 0.1) { node, _ in
            node.geometry?.firstMaterial?.emission.contents = PlatformColor.black
        }
        
        let flashSequence = SCNAction.sequence([flash, unflash])
        target.runAction(flashSequence)
    }
    
    // MARK: - User Interaction
    
    func highlightNodes(atPoint point: CGPoint) {
        let hitResults = self.sceneRenderer.hitTest(point, options: [:])
        
        for result in hitResults {
            if let nodeName = result.node.name {
                if let character = findCharacterByName(nodeName) {
                    showCharacterInfo(character)
                }
                
                if let hero = currentHeroes.first(where: { $0.name == nodeName }) {
                    showHeroMenu(hero)
                } else if let enemy = encounterEnemies.first(where: { $0.name == nodeName }) {
                    if !combatManager.isInCombat {
                        encounterEnemies = [enemy]
                        createEnemyNodes()
                        combatManager.startCombat(heroes: currentHeroes, enemies: encounterEnemies)
                    }
                }
            }
            
            guard let material = result.node.geometry?.firstMaterial else { continue }
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                material.emission.contents = PlatformColor.black
                SCNTransaction.commit()
            }
            
            material.emission.contents = PlatformColor.red
            SCNTransaction.commit()
        }
    }
    
    private func findCharacterByName(_ name: String) -> Character? {
        if let hero = currentHeroes.first(where: { $0.name == name }) {
            return hero
        }
        if let enemy = encounterEnemies.first(where: { $0.name == name }) {
            return enemy
        }
        return nil
    }
    
    private func showCharacterInfo(_ character: Character) {
        print("\n=== \(character.name) ===")
        print(character.displayDetailedStatus())
        
        if let hero = character as? Hero {
            print("\nLevel: \(hero.level)")
            print("Erfahrung: \(hero.experience)")
            print(hero.inventory.description)
        }
    }
    
    private func showHeroMenu(_ hero: Hero) {
        print("\n=== Held-Menü für \(hero.name) ===")
        print("1. Status anzeigen")
        print("2. Inventar öffnen")
        print("3. Fähigkeiten")
        print("4. Zufälliger Kampf")
        print("5. Bosskampf")
    }
    
    // MARK: - Game State Management
    
    func processGameState() {
        updateAllHealthBars()
        
        if combatManager.isInCombat {
            return
        }
        
        currentHeroes = currentHeroes.filter { $0.isAlive() }
        encounterEnemies = encounterEnemies.filter { $0.isAlive() }
        
        if currentHeroes.isEmpty {
            handleGameOver()
        }
        
        if encounterEnemies.isEmpty && combatManager.combatResult == .victory {
            handleVictory()
        }
    }
    
    private func handleGameOver() {
        print("\n💀 === GAME OVER ===")
        print("Alle Helden wurden besiegt!")
        
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 3_000_000_000)
            resetGame()
        }
    }
    
    private func handleVictory() {
        print("\n🎉 === SIEG! ===")
        print("Die Feinde wurden besiegt!")
        
        enemyNodes.forEach { $0.removeFromParentNode() }
        enemyNodes.removeAll()
        encounterEnemies.removeAll()
    }
    
    private func resetGame() {
        setupRPGSystem()
        enemyNodes.forEach { $0.removeFromParentNode() }
        enemyNodes.removeAll()
        encounterEnemies.removeAll()
        
        print("\n🔄 === SPIEL NEUGESTARTET ===")
    }
    
    // MARK: - Scene Renderer Delegate
    
    nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        Task { @MainActor in
            processGameState()
        }
    }
    
    // MARK: - Public API
    
    func getCurrentHeroes() -> [Hero] {
        return currentHeroes
    }
    
    func getCombatManager() -> CombatManager {
        return combatManager
    }
    
    func isInCombat() -> Bool {
        return combatManager.isInCombat
    }
    
    func getCombatStatus() -> String {
        return combatManager.getCombatStatus()
    }
}
