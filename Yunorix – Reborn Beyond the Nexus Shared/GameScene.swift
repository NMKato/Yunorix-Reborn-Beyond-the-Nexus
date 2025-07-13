//
//  GameScene.swift
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

// MARK: - Game Scene Manager

@MainActor
class GameScene: ObservableObject {
    
    // MARK: - Scene Properties
    
    let scene: SCNScene
    let cameraNode: SCNNode
    let lightNode: SCNNode
    let ambientLightNode: SCNNode
    
    // MARK: - World Properties
    
    let worldSize: Double = 20.0 // 20x20 meter world
    var groundNode: SCNNode
    var worldNodes: [SCNNode] = []
    
    // MARK: - Game Objects
    
    @Published var playerCharacter: SceneKitHero?
    @Published var enemies: [SceneKitEnemy] = []
    @Published var npcs: [SceneKitCharacter] = []
    @Published var isGameReady: Bool = false
    
    // MARK: - Managers
    
    private let assetManager = AssetManager.shared
    private var physicsWorld: SCNPhysicsWorld
    
    // MARK: - Camera Control
    
    @Published var cameraFollowsPlayer: Bool = true
    @Published var cameraDistance: Double = 8.0
    @Published var cameraAngle: Double = 45.0
    
    // MARK: - Initialization
    
    init() {
        // Create main scene
        self.scene = SCNScene()
        self.physicsWorld = scene.physicsWorld
        
        // Setup camera
        self.cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.position = SCNVector3(0, 6, 8)
        cameraNode.eulerAngles = SCNVector3(-0.5, 0, 0)
        cameraNode.name = "GameCamera"
        
        // Setup lighting
        self.lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.light?.color = PlatformColor.white
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(10, 15, 10)
        lightNode.eulerAngles = SCNVector3(-Double.pi/4, Double.pi/4, 0)
        lightNode.name = "DirectionalLight"
        
        self.ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = PlatformColor.white.withAlphaComponent(0.3)
        ambientLightNode.light?.intensity = 300
        ambientLightNode.name = "AmbientLight"
        
        // Create ground
        self.groundNode = SCNNode()
        
        // Add nodes to scene
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(ambientLightNode)
        scene.rootNode.addChildNode(groundNode)
        
        // Setup physics
        setupPhysics()
        
        // Build the world
        buildWorld()
    }
    
    // MARK: - Physics Setup
    
    private func setupPhysics() {
        physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        physicsWorld.timeStep = 1.0/60.0
    }
    
    // MARK: - World Building
    
    private func buildWorld() {
        print("🏗️ Building game world...")
        
        // Create ground plane
        createGround()
        
        // Add trees
        addTrees()
        
        // Add rocks and obstacles
        addRocks()
        
        // Add decorative elements
        addDecorations()
        
        // Create paths
        createPaths()
        
        // Spawn player
        spawnPlayer()
        
        // Spawn enemies
        spawnEnemies()
        
        isGameReady = true
        print("✅ Game world ready!")
    }
    
    private func createGround() {
        let groundGeometry = SCNPlane(width: CGFloat(worldSize), height: CGFloat(worldSize))
        groundGeometry.firstMaterial?.diffuse.contents = PlatformColor.green
        groundGeometry.firstMaterial?.normal.contents = "grass_normal"
        groundGeometry.firstMaterial?.roughness.contents = 0.8
        
        let ground = SCNNode(geometry: groundGeometry)
        ground.eulerAngles = SCNVector3(-Double.pi/2, 0, 0)
        ground.position = SCNVector3(0, 0, 0)
        ground.name = "Ground"
        
        // Add physics body for ground
        let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
        ground.physicsBody = SCNPhysicsBody(type: .static, shape: groundShape)
        ground.physicsBody?.categoryBitMask = 1
        ground.physicsBody?.collisionBitMask = 2
        
        groundNode.addChildNode(ground)
    }
    
    private func addTrees() {
        let treeCount = 15
        
        for _ in 0..<treeCount {
            let x = Double.random(in: -worldSize/2...worldSize/2)
            let z = Double.random(in: -worldSize/2...worldSize/2)
            
            // Avoid center area (player spawn)
            if abs(x) < 3 && abs(z) < 3 { continue }
            
            // Get random tree asset
            if let treeAsset = assetManager.getRandomAsset(from: .nature),
               let treeNode = assetManager.loadAsset(named: treeAsset.name) {
                
                treeNode.position = SCNVector3(x, 0, z)
                treeNode.name = "Tree_\(treeAsset.name)"
                
                // Add physics body
                let treeShape = SCNPhysicsShape(node: treeNode, options: [.type: SCNPhysicsShape.ShapeType.boundingBox])
                treeNode.physicsBody = SCNPhysicsBody(type: .static, shape: treeShape)
                treeNode.physicsBody?.categoryBitMask = 1
                treeNode.physicsBody?.collisionBitMask = 2
                
                scene.rootNode.addChildNode(treeNode)
                worldNodes.append(treeNode)
            }
        }
    }
    
    private func addRocks() {
        let rockCount = 8
        
        for _ in 0..<rockCount {
            let x = Double.random(in: -worldSize/2...worldSize/2)
            let z = Double.random(in: -worldSize/2...worldSize/2)
            
            // Avoid center and tree areas
            if abs(x) < 4 && abs(z) < 4 { continue }
            
            // Create simple rock for now (since we don't have rock assets yet)
            let rockGeometry = SCNBox(width: Double.random(in: 0.8...1.5), 
                                    height: Double.random(in: 0.5...1.0), 
                                    length: Double.random(in: 0.8...1.5), 
                                    chamferRadius: 0.1)
            rockGeometry.firstMaterial?.diffuse.contents = PlatformColor.gray
            rockGeometry.firstMaterial?.roughness.contents = 0.9
            
            let rock = SCNNode(geometry: rockGeometry)
            rock.position = SCNVector3(x, 0.5, z)
            rock.name = "Rock"
            
            // Add physics body
            let rockShape = SCNPhysicsShape(geometry: rockGeometry, options: nil)
            rock.physicsBody = SCNPhysicsBody(type: .static, shape: rockShape)
            rock.physicsBody?.categoryBitMask = 1
            rock.physicsBody?.collisionBitMask = 2
            
            scene.rootNode.addChildNode(rock)
            worldNodes.append(rock)
        }
    }
    
    private func addDecorations() {
        let decorationCount = 10
        
        for _ in 0..<decorationCount {
            let x = Double.random(in: -worldSize/2...worldSize/2)
            let z = Double.random(in: -worldSize/2...worldSize/2)
            
            // Small decorative objects
            let decorGeometry = SCNSphere(radius: Double.random(in: 0.1...0.3))
            decorGeometry.firstMaterial?.diffuse.contents = [PlatformColor.yellow, PlatformColor.purple, PlatformColor.orange].randomElement()
            decorGeometry.firstMaterial?.emission.contents = decorGeometry.firstMaterial?.diffuse.contents
            
            let decoration = SCNNode(geometry: decorGeometry)
            decoration.position = SCNVector3(x, 0.2, z)
            decoration.name = "Decoration"
            
            // Floating animation
            let float = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 2.0),
                SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 2.0)
            ])
            decoration.runAction(SCNAction.repeatForever(float))
            
            scene.rootNode.addChildNode(decoration)
            worldNodes.append(decoration)
        }
    }
    
    private func createPaths() {
        // Create a simple cross-shaped path
        let pathWidth: Double = 1.0
        let pathColor = PlatformColor.brown
        
        // Horizontal path
        let hPathGeometry = SCNPlane(width: CGFloat(worldSize), height: CGFloat(pathWidth))
        hPathGeometry.firstMaterial?.diffuse.contents = pathColor
        
        let hPath = SCNNode(geometry: hPathGeometry)
        hPath.position = SCNVector3(0, 0.01, 0)
        hPath.eulerAngles = SCNVector3(-Double.pi/2, 0, 0)
        hPath.name = "HorizontalPath"
        
        // Vertical path
        let vPathGeometry = SCNPlane(width: CGFloat(pathWidth), height: CGFloat(worldSize))
        vPathGeometry.firstMaterial?.diffuse.contents = pathColor
        
        let vPath = SCNNode(geometry: vPathGeometry)
        vPath.position = SCNVector3(0, 0.01, 0)
        vPath.eulerAngles = SCNVector3(-Double.pi/2, 0, 0)
        vPath.name = "VerticalPath"
        
        scene.rootNode.addChildNode(hPath)
        scene.rootNode.addChildNode(vPath)
        worldNodes.append(hPath)
        worldNodes.append(vPath)
    }
    
    // MARK: - Character Spawning
    
    private func spawnPlayer() {
        // Create player character (using Mage as default)
        let player = SceneKitMage(name: "Player")
        player.worldPosition = SCNVector3(0, 0, 0)
        
        // Add physics body for player
        let playerShape = SCNPhysicsShape(geometry: SCNBox(width: 0.6, height: 1.8, length: 0.6, chamferRadius: 0.1), options: nil)
        player.node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: playerShape)
        player.node.physicsBody?.categoryBitMask = 2
        player.node.physicsBody?.collisionBitMask = 1
        
        scene.rootNode.addChildNode(player.node)
        self.playerCharacter = player
        
        print("👤 Player spawned at origin")
    }
    
    private func spawnEnemies() {
        let enemyCount = 3
        
        for i in 0..<enemyCount {
            let angle = Double(i) * (Double.pi * 2 / Double(enemyCount))
            let distance = 6.0
            let x = cos(angle) * distance
            let z = sin(angle) * distance
            
            let enemy = SceneKitEnemy(name: "Enemy \(i+1)", maxHP: 60, attack: 10, defense: 4, difficulty: .medium)
            enemy.worldPosition = SCNVector3(x, 0, z)
            
            // Add physics body
            let enemyShape = SCNPhysicsShape(geometry: SCNBox(width: 0.6, height: 1.8, length: 0.6, chamferRadius: 0.1), options: nil)
            enemy.node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: enemyShape)
            enemy.node.physicsBody?.categoryBitMask = 2
            enemy.node.physicsBody?.collisionBitMask = 1
            
            scene.rootNode.addChildNode(enemy.node)
            enemies.append(enemy)
        }
        
        print("👹 Spawned \(enemyCount) enemies")
    }
    
    // MARK: - Camera Control
    
    func updateCamera() {
        guard let player = playerCharacter, cameraFollowsPlayer else { return }
        
        let playerPos = player.worldPosition
        let cameraX = playerPos.x + cos(cameraAngle) * cameraDistance
        let cameraY = playerPos.y + 6.0
        let cameraZ = playerPos.z + sin(cameraAngle) * cameraDistance
        
        cameraNode.position = SCNVector3(cameraX, cameraY, cameraZ)
        cameraNode.look(at: playerPos)
    }
    
    func setCameraDistance(_ distance: Double) {
        cameraDistance = max(3.0, min(15.0, distance))
        updateCamera()
    }
    
    func setCameraAngle(_ angle: Double) {
        cameraAngle = angle
        updateCamera()
    }
    
    // MARK: - Player Control
    
    func movePlayer(to position: SCNVector3) {
        guard let player = playerCharacter else { return }
        
        // Check if position is within world bounds
        let clampedX = max(-worldSize/2 + 1, min(worldSize/2 - 1, Double(position.x)))
        let clampedZ = max(-worldSize/2 + 1, min(worldSize/2 - 1, Double(position.z)))
        let clampedPosition = SCNVector3(clampedX, 0, clampedZ)
        
        player.moveTo(position: clampedPosition) { [weak self] in
            self?.updateCamera()
        }
    }
    
    func selectCharacter(at position: SCNVector3) -> SceneKitCharacter? {
        let threshold: Double = 1.5
        
        // Check player
        if let player = playerCharacter {
            let distance = simd_distance(simd_float3(player.worldPosition), simd_float3(position))
            if distance < threshold {
                player.setSelected(true)
                return player
            } else {
                player.setSelected(false)
            }
        }
        
        // Check enemies
        for enemy in enemies {
            let distance = simd_distance(simd_float3(enemy.worldPosition), simd_float3(position))
            if distance < threshold {
                enemy.setSelected(true)
                return enemy
            } else {
                enemy.setSelected(false)
            }
        }
        
        return nil
    }
    
    // MARK: - Combat Integration
    
    func startCombat(with enemy: SceneKitEnemy) {
        guard let player = playerCharacter else { return }
        
        print("⚔️ Combat started between \(player.name) and \(enemy.name)")
        
        // Play attack animation
        player.playAttackAnimation(target: enemy)
        
        // Simulate combat turn
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let mage = player as? SceneKitMage {
                mage.heal(target: player, amount: 10)
            }
        }
    }
    
    // MARK: - Asset Loading Status
    
    func preloadAssets() async {
        print("🔄 Preloading game assets...")
        
        // Load character assets
        _ = assetManager.loadAsset(named: "character_medium")
        _ = assetManager.loadAsset(named: "character_main")
        
        // Load nature assets
        _ = assetManager.loadAsset(named: "tree_default")
        _ = assetManager.loadAsset(named: "tree_tall")
        
        print("✅ Assets preloaded")
    }
    
    // MARK: - Performance Optimization
    
    func optimizePerformance() {
        // Level of detail based on distance from camera
        guard let cameraPos = cameraNode.position else { return }
        
        for node in worldNodes {
            let distance = simd_distance(simd_float3(node.position), simd_float3(cameraPos))
            
            if distance > 15.0 {
                // Hide distant objects
                node.isHidden = true
            } else if distance > 10.0 {
                // Reduce detail for medium distance
                node.isHidden = false
                node.renderingOrder = -1
            } else {
                // Full detail for close objects
                node.isHidden = false
                node.renderingOrder = 0
            }
        }
    }
    
    // MARK: - Debug Information
    
    func getDebugInfo() -> String {
        var info = ["=== Game Scene Debug ==="]
        info.append("World Size: \(worldSize)x\(worldSize)m")
        info.append("World Objects: \(worldNodes.count)")
        info.append("Enemies: \(enemies.count)")
        
        if let player = playerCharacter {
            info.append("Player Position: \(player.worldPosition)")
            info.append("Player Health: \(Int(player.healthPoints))/\(Int(player.maxHealthPoints))")
        }
        
        info.append("Camera Distance: \(String(format: "%.1f", cameraDistance))")
        info.append("Game Ready: \(isGameReady)")
        
        return info.joined(separator: "\n")
    }
}

// MARK: - Scene Renderer Delegate

extension GameScene {
    
    func update(atTime time: TimeInterval) {
        // Update camera
        updateCamera()
        
        // Optimize performance every few frames
        if Int(time * 60) % 60 == 0 {
            optimizePerformance()
        }
        
        // Process character status effects
        playerCharacter?.processStatusEffects()
        enemies.forEach { $0.processStatusEffects() }
    }
}