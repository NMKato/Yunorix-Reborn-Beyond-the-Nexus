//
//  AssetManager.swift
//  Yunorix – Reborn Beyond the Nexus Shared
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation
import SceneKit

#if os(macOS)
    import AppKit
    typealias PlatformColor = NSColor
    typealias PlatformImage = NSImage
#else
    import UIKit
    typealias PlatformColor = UIColor
    typealias PlatformImage = UIImage
#endif

// MARK: - Asset Categories

enum AssetCategory {
    case character
    case nature
    case ui
    case animation
}

enum AssetType {
    case tree(TreeType)
    case rock(RockType)
    case ground(GroundType)
    case decoration(DecorationType)
    case character(CharacterType)
    case ui(UIType)
    
    enum TreeType {
        case defaultTree, palmTree, tallTree, thinTree, fallTree
    }
    
    enum RockType {
        case small, medium, large, cliff
    }
    
    enum GroundType {
        case grass, path, river, dirt
    }
    
    enum DecorationType {
        case flower, grass, campfire, fence, bridge
    }
    
    enum CharacterType {
        case hero, enemy, npc
    }
    
    enum UIType {
        case button, healthBar, icon, slider
    }
}

struct GameAsset {
    let name: String
    let category: AssetCategory
    let type: AssetType
    let path: String
    let scale: Double
    let priority: Int
    
    init(name: String, category: AssetCategory, type: AssetType, path: String, scale: Double = 1.0, priority: Int = 0) {
        self.name = name
        self.category = category
        self.type = type
        self.path = path
        self.scale = scale
        self.priority = priority
    }
}

// MARK: - Asset Manager

@MainActor
class AssetManager: ObservableObject {
    
    static let shared = AssetManager()
    
    private var loadedAssets: [String: SCNNode] = [:]
    private var assetInventory: [GameAsset] = []
    private let assetBasePath = "/Users/4gi.tv/Documents/Yunorix – Reborn Beyond the Nexus/grafic objekts/"
    
    private init() {
        scanAssets()
    }
    
    // MARK: - Asset Discovery
    
    private func scanAssets() {
        print("🔍 Scanning assets...")
        
        // Nature Assets
        scanNatureAssets()
        
        // Character Assets
        scanCharacterAssets()
        
        // UI Assets
        scanUIAssets()
        
        print("📦 Found \(assetInventory.count) assets")
    }
    
    private func scanNatureAssets() {
        let natureAssets = [
            // Trees
            GameAsset(name: "tree_default", category: .nature, type: .tree(.defaultTree), 
                     path: "nature-kit/Models/FBX format/tree_default.fbx", scale: 3.0, priority: 5),
            GameAsset(name: "tree_tall", category: .nature, type: .tree(.tallTree), 
                     path: "nature-kit/Models/FBX format/tree_tall.fbx", scale: 4.0, priority: 4),
            GameAsset(name: "tree_palm", category: .nature, type: .tree(.palmTree), 
                     path: "nature-kit/Models/FBX format/tree_palmShort.fbx", scale: 2.5, priority: 3),
            GameAsset(name: "tree_thin", category: .nature, type: .tree(.thinTree), 
                     path: "nature-kit/Models/FBX format/tree_thin_fall.fbx", scale: 2.8, priority: 4),
            
            // Rocks & Cliffs
            GameAsset(name: "cliff_stone", category: .nature, type: .rock(.cliff), 
                     path: "nature-kit/Models/FBX format/cliff_stone.fbx", scale: 2.0, priority: 6),
            GameAsset(name: "stump_detailed", category: .nature, type: .rock(.medium), 
                     path: "nature-kit/Models/FBX format/stump_squareDetailed.fbx", scale: 1.5, priority: 2),
            
            // Ground & Paths
            GameAsset(name: "path_wood_corner", category: .nature, type: .ground(.path), 
                     path: "nature-kit/Models/FBX format/path_woodCorner.fbx", scale: 1.0, priority: 7),
            GameAsset(name: "path_stone_corner", category: .nature, type: .ground(.path), 
                     path: "nature-kit/Models/FBX format/path_stoneCorner.fbx", scale: 1.0, priority: 7),
            
            // Decorations
            GameAsset(name: "campfire_planks", category: .nature, type: .decoration(.campfire), 
                     path: "nature-kit/Models/FBX format/campfire_planks.fbx", scale: 1.2, priority: 3),
            GameAsset(name: "statue_ring", category: .nature, type: .decoration(.campfire), 
                     path: "nature-kit/Models/FBX format/statue_ring.fbx", scale: 1.8, priority: 2),
            
            // Crops
            GameAsset(name: "bamboo_stage_a", category: .nature, type: .decoration(.grass), 
                     path: "nature-kit/Models/FBX format/crops_bambooStageA.fbx", scale: 1.0, priority: 1),
            GameAsset(name: "leafs_stage_a", category: .nature, type: .decoration(.grass), 
                     path: "nature-kit/Models/FBX format/crops_leafsStageA.fbx", scale: 0.8, priority: 1)
        ]
        
        assetInventory.append(contentsOf: natureAssets)
    }
    
    private func scanCharacterAssets() {
        let characterAssets = [
            GameAsset(name: "character_medium", category: .character, type: .character(.hero), 
                     path: "animated-characters-2/Model/characterMedium.fbx", scale: 1.8, priority: 10),
            GameAsset(name: "character_main", category: .character, type: .character(.hero), 
                     path: "character.fbx", scale: 1.8, priority: 9),
            GameAsset(name: "character_alt1", category: .character, type: .character(.enemy), 
                     path: "character (1).fbx", scale: 1.8, priority: 8),
            GameAsset(name: "character_alt2", category: .character, type: .character(.enemy), 
                     path: "character (2).fbx", scale: 1.8, priority: 8),
            GameAsset(name: "character_4", category: .character, type: .character(.enemy), 
                     path: "character 4.fbx", scale: 1.8, priority: 7),
            GameAsset(name: "character_5", category: .character, type: .character(.npc), 
                     path: "character 5.fbx", scale: 1.8, priority: 6),
            GameAsset(name: "character_6", category: .character, type: .character(.npc), 
                     path: "character 6.fbx", scale: 1.8, priority: 6)
        ]
        
        assetInventory.append(contentsOf: characterAssets)
    }
    
    private func scanUIAssets() {
        // UI Assets sind PNG-basiert, werden separat in UIManager gehandhabt
        print("📱 UI Assets: Health bars, buttons, icons available")
    }
    
    // MARK: - Asset Loading
    
    func loadAsset(named name: String) -> SCNNode? {
        // Check cache first
        if let cachedNode = loadedAssets[name] {
            return cachedNode.clone()
        }
        
        // Find asset in inventory
        guard let asset = assetInventory.first(where: { $0.name == name }) else {
            print("❌ Asset not found: \(name)")
            return nil
        }
        
        let fullPath = assetBasePath + asset.path
        
        // Load based on file extension
        if asset.path.hasSuffix(".fbx") || asset.path.hasSuffix(".dae") {
            return loadFBXAsset(from: fullPath, asset: asset)
        } else if asset.path.hasSuffix(".scn") {
            return loadSCNAsset(from: fullPath, asset: asset)
        }
        
        print("❌ Unsupported asset format: \(asset.path)")
        return nil
    }
    
    private func loadFBXAsset(from path: String, asset: GameAsset) -> SCNNode? {
        let url = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ Asset file not found: \(path)")
            return createFallbackNode(for: asset)
        }
        
        do {
            let scene = try SCNScene(url: url, options: [
                .checkConsistency: true,
                .flattenScene: false,
                .createNormalsIfAbsent: true
            ])
            
            let rootNode = SCNNode()
            
            // Copy all child nodes
            for child in scene.rootNode.childNodes {
                rootNode.addChildNode(child.clone())
            }
            
            // Apply scaling
            rootNode.scale = SCNVector3(asset.scale, asset.scale, asset.scale)
            
            // Optimize materials
            optimizeMaterials(for: rootNode)
            
            // Cache the asset
            loadedAssets[asset.name] = rootNode
            
            print("✅ Loaded asset: \(asset.name)")
            return rootNode.clone()
            
        } catch {
            print("❌ Failed to load \(asset.name): \(error)")
            return createFallbackNode(for: asset)
        }
    }
    
    private func loadSCNAsset(from path: String, asset: GameAsset) -> SCNNode? {
        guard let scene = SCNScene(named: path) else {
            print("❌ Failed to load SCN: \(path)")
            return createFallbackNode(for: asset)
        }
        
        let rootNode = scene.rootNode.clone()
        rootNode.scale = SCNVector3(asset.scale, asset.scale, asset.scale)
        
        loadedAssets[asset.name] = rootNode
        return rootNode.clone()
    }
    
    private func createFallbackNode(for asset: GameAsset) -> SCNNode {
        let node = SCNNode()
        
        switch asset.type {
        case .tree:
            // Simple tree representation
            let trunk = SCNBox(width: 0.2, height: 2.0, length: 0.2, chamferRadius: 0.05)
            trunk.firstMaterial?.diffuse.contents = PlatformColor.brown
            let trunkNode = SCNNode(geometry: trunk)
            trunkNode.position = SCNVector3(0, 1, 0)
            
            let leaves = SCNSphere(radius: 0.8)
            leaves.firstMaterial?.diffuse.contents = PlatformColor.green
            let leavesNode = SCNNode(geometry: leaves)
            leavesNode.position = SCNVector3(0, 2.5, 0)
            
            node.addChildNode(trunkNode)
            node.addChildNode(leavesNode)
            
        case .rock:
            let rock = SCNBox(width: 1.0, height: 0.8, length: 1.2, chamferRadius: 0.1)
            rock.firstMaterial?.diffuse.contents = PlatformColor.gray
            node.geometry = rock
            
        case .character:
            let body = SCNBox(width: 0.6, height: 1.8, length: 0.3, chamferRadius: 0.1)
            body.firstMaterial?.diffuse.contents = PlatformColor.blue
            node.geometry = body
            
        default:
            let placeholder = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
            placeholder.firstMaterial?.diffuse.contents = PlatformColor.purple
            node.geometry = placeholder
        }
        
        node.scale = SCNVector3(asset.scale, asset.scale, asset.scale)
        print("⚠️ Using fallback for: \(asset.name)")
        return node
    }
    
    private func optimizeMaterials(for node: SCNNode) {
        // Optimize materials for better performance
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                for material in geometry.materials {
                    // Enable lighting optimizations
                    material.lightingModel = .blinn
                    material.isDoubleSided = false
                    
                    // Optimize texture settings
                    if let diffuse = material.diffuse.contents as? PlatformImage {
                        material.diffuse.contents = diffuse
                        material.diffuse.wrapS = .repeat
                        material.diffuse.wrapT = .repeat
                    }
                }
            }
            return true
        }
    }
    
    // MARK: - Asset Queries
    
    func getAssetsByCategory(_ category: AssetCategory) -> [GameAsset] {
        return assetInventory.filter { $0.category == category }
    }
    
    func getAssetsByType<T>(_ type: T) -> [GameAsset] where T: Equatable {
        return assetInventory.filter { asset in
            switch (asset.type, type) {
            case (.tree(let assetTreeType), let queryType as AssetType.TreeType):
                return assetTreeType == queryType
            case (.rock(let assetRockType), let queryType as AssetType.RockType):
                return assetRockType == queryType
            case (.character(let assetCharType), let queryType as AssetType.CharacterType):
                return assetCharType == queryType
            default:
                return false
            }
        }
    }
    
    func getRandomAsset(from category: AssetCategory) -> GameAsset? {
        let categoryAssets = getAssetsByCategory(category)
        return categoryAssets.randomElement()
    }
    
    // MARK: - Animation Support
    
    func loadAnimations(for characterName: String) -> [String: CAAnimation] {
        var animations: [String: CAAnimation] = [:]
        
        let animationPaths = [
            "idle": "animated-characters-2/Animations/idle.fbx",
            "run": "animated-characters-2/Animations/run.fbx",
            "jump": "animated-characters-2/Animations/jump.fbx"
        ]
        
        for (animName, animPath) in animationPaths {
            let fullPath = assetBasePath + animPath
            
            if let scene = try? SCNScene(url: URL(fileURLWithPath: fullPath), options: nil) {
                // Extract animation from scene
                if let animationKeys = scene.rootNode.animationKeys.first,
                   let animation = scene.rootNode.animation(forKey: animationKeys) {
                    animations[animName] = animation
                }
            }
        }
        
        print("🎬 Loaded \(animations.count) animations for \(characterName)")
        return animations
    }
}