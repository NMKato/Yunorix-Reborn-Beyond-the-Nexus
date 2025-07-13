//
//  OpenWorldController.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Created by NMK Solutions on 12.07.25.
//

import SceneKit
import SwiftUI
import GameplayKit

#if canImport(RealityKit)
import RealityKit
#endif

@MainActor
class OpenWorldController: NSObject, ObservableObject {
    
    // MARK: - Core Properties
    
    private var sceneView: SCNView!
    private var gameScene: SCNScene!
    private var cameraNode: SCNNode!
    private var playerNode: SCNNode!
    private var worldNode: SCNNode!
    
    // Movement system
    private var playerVelocity = SCNVector3Zero
    private var isMoving = false
    private var movementDirection = SCNVector3Zero
    private var cameraTarget = SCNVector3Zero
    
    // World properties
    private let worldSize: Float = 50.0  // 50x50 meter open world
    private let playerSpeed: Float = 5.0
    private let cameraHeight: Float = 8.0
    private let cameraDistance: Float = 12.0
    
    // Game state
    @Published var playerPosition = SCNVector3Zero
    @Published var playerHealth: Float = 100.0
    @Published var playerMana: Float = 100.0
    @Published var collectedItems: Int = 0
    @Published var gameMessage = "Explore the open world!"
    
    // Collectibles and enemies
    private var collectibles: [SCNNode] = []
    private var enemies: [SCNNode] = []
    private var portals: [SCNNode] = []
    
    // Input handling
    private var currentInputVector = CGPoint.zero
    private var isUsingKeyboard = false
    
    // MARK: - Initialization
    
    func setupOpenWorld(in sceneView: SCNView) {
        self.sceneView = sceneView
        
        createScene()
        setupCamera()
        createPlayer()
        generateWorld()
        spawnCollectibles()
        spawnEnemies()
        setupLighting()
        setupPhysics()
        
        // Start game loop
        startGameLoop()
        
        gameMessage = "Welcome to the Open World! Move with WASD or touch controls."
    }
    
    // MARK: - Scene Creation
    
    private func createScene() {
        gameScene = SCNScene()
        sceneView.scene = gameScene
        sceneView.backgroundColor = UIColor.black
        
        // World root node
        worldNode = SCNNode()
        gameScene.rootNode.addChildNode(worldNode)
    }
    
    private func setupCamera() {
        // Camera setup for third-person view
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 200.0
        
        // Enable camera controls for additional manual adjustment
        sceneView.allowsCameraControl = false // We handle camera manually
        sceneView.defaultCameraController.interactionMode = .orbitTurntable
        
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    private func createPlayer() {
        // Create player character
        let playerGeometry = SCNSphere(radius: 0.9)
        
        // Player material with glow effect
        let playerMaterial = SCNMaterial()
        playerMaterial.diffuse.contents = UIColor.systemBlue
        playerMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.3)
        playerMaterial.specular.contents = UIColor.white
        playerGeometry.materials = [playerMaterial]
        
        playerNode = SCNNode(geometry: playerGeometry)
        playerNode.position = SCNVector3(0, 1, 0)
        playerNode.name = "player"
        
        // Add physics body for collision detection
        playerNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: playerGeometry))
        playerNode.physicsBody?.categoryBitMask = 1
        playerNode.physicsBody?.contactTestBitMask = 2 | 4 // Collectibles and enemies
        
        worldNode.addChildNode(playerNode)
        playerPosition = playerNode.position
        
        // Add player glow effect
        addPlayerEffects()
    }
    
    private func addPlayerEffects() {
        // Add particle system for magical aura
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 20
        particleSystem.particleLifeSpan = 2.0
        particleSystem.emissionDuration = 0
        particleSystem.particleSize = 0.1
        particleSystem.particleVelocity = 2.0
        particleSystem.particleVelocityVariation = 1.0
        particleSystem.particleColor = UIColor.cyan
        particleSystem.particleColorVariation = SCNVector4(0.2, 0.2, 0.2, 0)
        
        let particleNode = SCNNode()
        particleNode.addParticleSystem(particleSystem)
        playerNode.addChildNode(particleNode)
    }
    
    // MARK: - World Generation
    
    private func generateWorld() {
        createTerrain()
        createEnvironmentalElements()
        addPortals()
    }
    
    private func createTerrain() {
        // Create large ground plane
        let groundGeometry = SCNPlane(width: CGFloat(worldSize), height: CGFloat(worldSize))
        
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.8)
        groundMaterial.normal.contents = UIColor.systemBlue // Fake normal map effect
        groundMaterial.roughness.contents = 0.8
        groundGeometry.materials = [groundMaterial]
        
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2) // Rotate to lie flat
        groundNode.position = SCNVector3(0, 0, 0)
        groundNode.name = "ground"
        
        // Add physics for ground
        groundNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: groundGeometry))
        
        worldNode.addChildNode(groundNode)
        
        // Add texture patterns (paths, etc.)
        createPaths()
    }
    
    private func createPaths() {
        // Create intersecting paths across the world
        let pathWidth: Float = 2.0
        let pathColor = UIColor.brown.withAlphaComponent(0.7)
        
        // Horizontal path
        let hPath = SCNPlane(width: CGFloat(worldSize), height: CGFloat(pathWidth))
        hPath.materials.first?.diffuse.contents = pathColor
        let hPathNode = SCNNode(geometry: hPath)
        hPathNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
        hPathNode.position = SCNVector3(0, 0.01, 0)
        worldNode.addChildNode(hPathNode)
        
        // Vertical path
        let vPath = SCNPlane(width: CGFloat(pathWidth), height: CGFloat(worldSize))
        vPath.materials.first?.diffuse.contents = pathColor
        let vPathNode = SCNNode(geometry: vPath)
        vPathNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2)
        vPathNode.position = SCNVector3(0, 0.01, 0)
        worldNode.addChildNode(vPathNode)
    }
    
    private func createEnvironmentalElements() {
        // Add trees, rocks, and other environmental elements
        for i in 0..<30 {
            // Trees
            let tree = createTree()
            let x = Float.random(in: -worldSize/2...worldSize/2)
            let z = Float.random(in: -worldSize/2...worldSize/2)
            tree.position = SCNVector3(x, 0, z)
            worldNode.addChildNode(tree)
            
            // Rocks
            if i < 15 {
                let rock = createRock()
                let rockX = Float.random(in: -worldSize/2...worldSize/2)
                let rockZ = Float.random(in: -worldSize/2...worldSize/2)
                rock.position = SCNVector3(rockX, 0, rockZ)
                worldNode.addChildNode(rock)
            }
        }
    }
    
    private func createTree() -> SCNNode {
        let treeGroup = SCNNode()
        
        // Trunk
        let trunk = SCNBox(width: 0.5, height: 4.0, length: 0.5, chamferRadius: 0.1)
        trunk.materials.first?.diffuse.contents = UIColor.brown
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(0, 2, 0)
        
        // Leaves
        let leaves = SCNSphere(radius: 2.0)
        leaves.materials.first?.diffuse.contents = UIColor.systemGreen
        let leavesNode = SCNNode(geometry: leaves)
        leavesNode.position = SCNVector3(0, 5, 0)
        
        treeGroup.addChildNode(trunkNode)
        treeGroup.addChildNode(leavesNode)
        
        return treeGroup
    }
    
    private func createRock() -> SCNNode {
        let rock = SCNSphere(radius: CGFloat.random(in: 1.0...2.0))
        rock.materials.first?.diffuse.contents = UIColor.gray
        rock.materials.first?.roughness.contents = 0.9
        
        let rockNode = SCNNode(geometry: rock)
        rockNode.scale = SCNVector3(1, 0.6, 1) // Flatten slightly
        
        return rockNode
    }
    
    private func addPortals() {
        // Add magical portals at key locations
        let portalPositions = [
            SCNVector3(15, 1, 15),
            SCNVector3(-15, 1, 15),
            SCNVector3(-15, 1, -15),
            SCNVector3(15, 1, -15)
        ]
        
        for position in portalPositions {
            let portal = createPortal()
            portal.position = position
            worldNode.addChildNode(portal)
            portals.append(portal)
        }
    }
    
    private func createPortal() -> SCNNode {
        let portalGroup = SCNNode()
        
        // Portal ring
        let ring = SCNTorus(ringRadius: 2.0, pipeRadius: 0.2)
        let ringMaterial = SCNMaterial()
        ringMaterial.diffuse.contents = UIColor.systemPurple
        ringMaterial.emission.contents = UIColor.magenta.withAlphaComponent(0.5)
        ring.materials = [ringMaterial]
        
        let ringNode = SCNNode(geometry: ring)
        ringNode.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        
        // Add rotation animation
        let rotationAction = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 4.0)
        let repeatAction = SCNAction.repeatForever(rotationAction)
        ringNode.runAction(repeatAction)
        
        portalGroup.addChildNode(ringNode)
        portalGroup.name = "portal"
        
        return portalGroup
    }
    
    // MARK: - Collectibles and Enemies
    
    private func spawnCollectibles() {
        // Spawn collectible items throughout the world
        for i in 0..<25 {
            let collectible = createCollectible()
            let x = Float.random(in: -worldSize/2 + 5...worldSize/2 - 5)
            let z = Float.random(in: -worldSize/2 + 5...worldSize/2 - 5)
            collectible.position = SCNVector3(x, 1.5, z)
            
            worldNode.addChildNode(collectible)
            collectibles.append(collectible)
        }
    }
    
    private func createCollectible() -> SCNNode {
        let gem = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.1)
        
        let gemMaterial = SCNMaterial()
        gemMaterial.diffuse.contents = UIColor.systemYellow
        gemMaterial.emission.contents = UIColor.orange.withAlphaComponent(0.5)
        gemMaterial.metalness.contents = 0.8
        gem.materials = [gemMaterial]
        
        let collectibleNode = SCNNode(geometry: gem)
        collectibleNode.name = "collectible"
        
        // Add physics
        collectibleNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: gem))
        collectibleNode.physicsBody?.categoryBitMask = 2
        
        // Add floating animation
        let floatAction = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.0),
            SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 1.0)
        ])
        let repeatFloat = SCNAction.repeatForever(floatAction)
        collectibleNode.runAction(repeatFloat)
        
        // Add rotation
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3.0)
        let repeatRotate = SCNAction.repeatForever(rotateAction)
        collectibleNode.runAction(repeatRotate)
        
        return collectibleNode
    }
    
    private func spawnEnemies() {
        // Spawn enemies that patrol the world
        for i in 0..<8 {
            let enemy = createEnemy()
            let x = Float.random(in: -worldSize/2 + 10...worldSize/2 - 10)
            let z = Float.random(in: -worldSize/2 + 10...worldSize/2 - 10)
            enemy.position = SCNVector3(x, 1, z)
            
            worldNode.addChildNode(enemy)
            enemies.append(enemy)
            
            // Add patrol behavior
            addPatrolBehavior(to: enemy)
        }
    }
    
    private func createEnemy() -> SCNNode {
        let enemyGeometry = SCNSphere(radius: 0.8)
        
        let enemyMaterial = SCNMaterial()
        enemyMaterial.diffuse.contents = UIColor.systemRed
        enemyMaterial.emission.contents = UIColor.red.withAlphaComponent(0.2)
        enemyGeometry.materials = [enemyMaterial]
        
        let enemyNode = SCNNode(geometry: enemyGeometry)
        enemyNode.name = "enemy"
        
        // Add physics
        enemyNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: enemyGeometry))
        enemyNode.physicsBody?.categoryBitMask = 4
        
        return enemyNode
    }
    
    private func addPatrolBehavior(to enemy: SCNNode) {
        // Simple patrol AI - move in random directions
        let moveActions = [
            SCNAction.moveBy(x: 5, y: 0, z: 0, duration: 3.0),
            SCNAction.moveBy(x: -5, y: 0, z: 0, duration: 3.0),
            SCNAction.moveBy(x: 0, y: 0, z: 5, duration: 3.0),
            SCNAction.moveBy(x: 0, y: 0, z: -5, duration: 3.0)
        ]
        
        let randomMove = SCNAction.sequence([
            moveActions.randomElement()!,
            SCNAction.wait(duration: 1.0)
        ])
        
        let patrol = SCNAction.repeatForever(randomMove)
        enemy.runAction(patrol)
    }
    
    // MARK: - Movement System
    
    func updateMovement(inputVector: CGPoint, usingKeyboard: Bool = false) {
        currentInputVector = inputVector
        isUsingKeyboard = usingKeyboard
        
        // Convert input to world movement
        if inputVector.x != 0 || inputVector.y != 0 {
            isMoving = true
            
            // Calculate movement direction
            let cameraYaw = cameraNode.eulerAngles.y
            let forward = SCNVector3(-sin(cameraYaw), 0, -cos(cameraYaw))
            let right = SCNVector3(cos(cameraYaw), 0, -sin(cameraYaw))
            
            movementDirection = SCNVector3(
                forward.x * Float(inputVector.y) + right.x * Float(inputVector.x),
                0,
                forward.z * Float(inputVector.y) + right.z * Float(inputVector.x)
            )
            
            // Normalize movement direction
            let length = sqrt(movementDirection.x * movementDirection.x + movementDirection.z * movementDirection.z)
            if length > 0 {
                movementDirection = SCNVector3(
                    movementDirection.x / length,
                    0,
                    movementDirection.z / length
                )
            }
        } else {
            isMoving = false
            movementDirection = SCNVector3Zero
        }
    }
    
    func stopMovement() {
        isMoving = false
        currentInputVector = .zero
        movementDirection = SCNVector3Zero
    }
    
    // MARK: - Game Loop
    
    private func startGameLoop() {
        // Use scene view's built-in update mechanism
        sceneView.delegate = self
    }
    
    private func updateGameLogic(deltaTime: TimeInterval) {
        updatePlayerMovement(deltaTime: deltaTime)
        updateCamera()
        checkCollisions()
        updateEnemyAI(deltaTime: deltaTime)
    }
    
    private func updatePlayerMovement(deltaTime: TimeInterval) {
        guard isMoving else { return }
        
        let deltaMovement = SCNVector3(
            movementDirection.x * playerSpeed * Float(deltaTime),
            0,
            movementDirection.z * playerSpeed * Float(deltaTime)
        )
        
        let newPosition = SCNVector3(
            playerNode.position.x + deltaMovement.x,
            playerNode.position.y,
            playerNode.position.z + deltaMovement.z
        )
        
        // Clamp to world bounds
        let clampedPosition = SCNVector3(
            max(-worldSize/2 + 2, min(worldSize/2 - 2, newPosition.x)),
            newPosition.y,
            max(-worldSize/2 + 2, min(worldSize/2 - 2, newPosition.z))
        )
        
        playerNode.position = clampedPosition
        playerPosition = clampedPosition
    }
    
    private func updateCamera() {
        // Third-person camera that follows player
        let targetPosition = SCNVector3(
            playerNode.position.x,
            playerNode.position.y + cameraHeight,
            playerNode.position.z + cameraDistance
        )
        
        // Smooth camera movement
        let currentPosition = cameraNode.position
        let smoothFactor: Float = 0.1
        
        cameraNode.position = SCNVector3(
            currentPosition.x + (targetPosition.x - currentPosition.x) * smoothFactor,
            currentPosition.y + (targetPosition.y - currentPosition.y) * smoothFactor,
            currentPosition.z + (targetPosition.z - currentPosition.z) * smoothFactor
        )
        
        // Look at player
        cameraNode.look(at: playerNode.position)
    }
    
    private func checkCollisions() {
        // Check for collectible collection
        for (index, collectible) in collectibles.enumerated().reversed() {
            let distance = distanceBetween(playerNode.position, collectible.position)
            if distance < 2.0 {
                // Collect item
                collectItem(collectible, at: index)
            }
        }
        
        // Check for enemy encounters
        for enemy in enemies {
            let distance = distanceBetween(playerNode.position, enemy.position)
            if distance < 3.0 {
                // Start combat or take damage
                handleEnemyEncounter(enemy)
            }
        }
    }
    
    private func collectItem(_ item: SCNNode, at index: Int) {
        // Remove from world
        item.removeFromParentNode()
        collectibles.remove(at: index)
        
        // Update game state
        collectedItems += 1
        playerMana = min(100, playerMana + 10)
        gameMessage = "Collected magical essence! Items: \(collectedItems)"
        
        // Add collection effect
        addCollectionEffect(at: item.position)
    }
    
    private func handleEnemyEncounter(_ enemy: SCNNode) {
        // Simple damage system
        playerHealth = max(0, playerHealth - 0.5)
        gameMessage = "Enemy encounter! Health: \(Int(playerHealth))"
        
        if playerHealth <= 0 {
            gameMessage = "You have been defeated! Game Over!"
            // Handle game over
        }
    }
    
    private func addCollectionEffect(at position: SCNVector3) {
        // Add sparkle effect at collection point
        let sparkle = SCNParticleSystem()
        sparkle.birthRate = 100
        sparkle.particleLifeSpan = 1.0
        sparkle.emissionDuration = 0.5
        sparkle.particleSize = 0.1
        sparkle.particleColor = UIColor.yellow
        
        let effectNode = SCNNode()
        effectNode.position = position
        effectNode.addParticleSystem(sparkle)
        worldNode.addChildNode(effectNode)
        
        // Remove effect after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            effectNode.removeFromParentNode()
        }
    }
    
    private func updateEnemyAI(deltaTime: TimeInterval) {
        // Add simple AI behavior for enemies to react to player
        for enemy in enemies {
            let distanceToPlayer = distanceBetween(enemy.position, playerNode.position)
            
            if distanceToPlayer < 10.0 {
                // Move towards player
                let direction = SCNVector3(
                    playerNode.position.x - enemy.position.x,
                    0,
                    playerNode.position.z - enemy.position.z
                )
                
                let length = sqrt(direction.x * direction.x + direction.z * direction.z)
                if length > 0 {
                    let normalizedDirection = SCNVector3(
                        direction.x / length,
                        0,
                        direction.z / length
                    )
                    
                    let moveSpeed: Float = 2.0
                    let deltaMovement = SCNVector3(
                        normalizedDirection.x * moveSpeed * Float(deltaTime),
                        0,
                        normalizedDirection.z * moveSpeed * Float(deltaTime)
                    )
                    
                    enemy.position = SCNVector3(
                        enemy.position.x + deltaMovement.x,
                        enemy.position.y,
                        enemy.position.z + deltaMovement.z
                    )
                }
            }
        }
    }
    
    // MARK: - Utility Functions
    
    private func distanceBetween(_ pos1: SCNVector3, _ pos2: SCNVector3) -> Float {
        let dx = pos1.x - pos2.x
        let dy = pos1.y - pos2.y
        let dz = pos1.z - pos2.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    private func setupLighting() {
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white.withAlphaComponent(0.3)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        gameScene.rootNode.addChildNode(ambientNode)
        
        // Directional light (sun)
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1000
        directionalLight.castsShadow = true
        
        let lightNode = SCNNode()
        lightNode.light = directionalLight
        lightNode.position = SCNVector3(10, 20, 10)
        lightNode.look(at: SCNVector3Zero)
        gameScene.rootNode.addChildNode(lightNode)
    }
    
    private func setupPhysics() {
        sceneView.scene?.physicsWorld.contactDelegate = self
        sceneView.scene?.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
    }
}

// MARK: - SCNSceneRendererDelegate

extension OpenWorldController: SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update game logic each frame
        updateGameLogic(deltaTime: 1.0/60.0) // Assume 60 FPS
    }
}

// MARK: - SCNPhysicsContactDelegate

extension OpenWorldController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Handle physics collisions
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.name == "player" || nodeB.name == "player" {
            let otherNode = nodeA.name == "player" ? nodeB : nodeA
            
            if otherNode.name == "collectible" {
                if let index = collectibles.firstIndex(of: otherNode) {
                    collectItem(otherNode, at: index)
                }
            } else if otherNode.name == "enemy" {
                handleEnemyEncounter(otherNode)
            }
        }
    }
}