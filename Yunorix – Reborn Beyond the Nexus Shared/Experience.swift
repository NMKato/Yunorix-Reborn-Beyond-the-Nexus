//
//  Experience.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Generated from Reality Composer
//

#if canImport(RealityKit) && false  // Temporarily disabled for iOS build
import RealityKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
public class Experience {
    
    public class Box: Entity, HasModel, HasAnchoring, HasPhysics, HasCollision {
        
        public required init() {
            super.init()
            self.model = ModelComponent(
                mesh: .generateBox(size: [0.1, 0.1, 0.1]),
                materials: [SimpleMaterial(
                    color: .purple.withAlphaComponent(0.3),
                    isMetallic: false
                )]
            )
            
            self.anchoring = AnchoringComponent(.world(transform: simd_float4x4(1)))
            self.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: [0.1, 0.1, 0.1])])
            self.physicsBody = PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .dynamic
            )
        }
    }
    
    public class Crystal: Entity, HasModel, HasAnchoring {
        
        public required init() {
            super.init()
            
            // Create crystal geometry
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .cyan.withAlphaComponent(0.8))
            material.metallic = .init(floatLiteral: 0.9)
            material.roughness = .init(floatLiteral: 0.1)
            material.clearcoat = .init(floatLiteral: 1.0)
            
            self.model = ModelComponent(
                mesh: .generateSphere(radius: 0.05),
                materials: [material]
            )
            
            self.anchoring = AnchoringComponent(.world(transform: simd_float4x4(1)))
            
            // Add floating animation
            addFloatingAnimation()
        }
        
        private func addFloatingAnimation() {
            let floatUp = Transform(
                scale: SIMD3<Float>(1.0, 1.0, 1.0),
                rotation: simd_quatf(),
                translation: SIMD3<Float>(0, 0.02, 0)
            )
            
            let floatDown = Transform(
                scale: SIMD3<Float>(1.0, 1.0, 1.0),
                rotation: simd_quatf(),
                translation: SIMD3<Float>(0, -0.02, 0)
            )
            
            let upAnimation = FromToByAnimation<Transform>(
                name: "floatUp",
                from: .transform(floatDown),
                to: .transform(floatUp),
                duration: 2.0,
                timing: .easeInOut,
                isAdditive: true,
                repeatMode: .autoReverse,
                fillMode: .both
            )
            
            let animationController = self.playAnimation(upAnimation.repeat())
        }
    }
    
    public class MagicalOrb: Entity, HasModel, HasAnchoring {
        
        public required init() {
            super.init()
            
            // Create magical orb with particle effect
            var material = UnlitMaterial(color: .purple)
            material.color = .init(tint: .purple.withAlphaComponent(0.7))
            
            self.model = ModelComponent(
                mesh: .generateSphere(radius: 0.03),
                materials: [material]
            )
            
            self.anchoring = AnchoringComponent(.world(transform: simd_float4x4(1)))
            
            // Add pulsing glow effect
            addGlowAnimation()
        }
        
        private func addGlowAnimation() {
            let scaleUp = Transform(
                scale: SIMD3<Float>(1.2, 1.2, 1.2),
                rotation: simd_quatf(),
                translation: SIMD3<Float>(0, 0, 0)
            )
            
            let scaleDown = Transform(
                scale: SIMD3<Float>(0.8, 0.8, 0.8),
                rotation: simd_quatf(),
                translation: SIMD3<Float>(0, 0, 0)
            )
            
            let pulseAnimation = FromToByAnimation<Transform>(
                name: "pulse",
                from: .transform(scaleDown),
                to: .transform(scaleUp),
                duration: 1.5,
                timing: .easeInOut,
                isAdditive: false,
                repeatMode: .autoReverse,
                fillMode: .both
            )
            
            let animationController = self.playAnimation(pulseAnimation.repeat())
        }
    }
    
    public class EnvironmentSphere: Entity, HasModel, HasAnchoring {
        
        public required init() {
            super.init()
            
            // Create environment background sphere
            var material = UnlitMaterial()
            material.color = .init(tint: .black.withAlphaComponent(0.9))
            
            self.model = ModelComponent(
                mesh: .generateSphere(radius: 50.0),
                materials: [material]
            )
            
            // Invert sphere for inside view
            self.model?.mesh = self.model?.mesh.firstMaterial?.triangles.map { triangle in
                return triangle.reversed()
            } as? MeshResource ?? self.model!.mesh
            
            self.anchoring = AnchoringComponent(.world(transform: simd_float4x4(1)))
        }
    }
    
    // MARK: - Scene Loading Functions
    
    public static func loadBox() throws -> Experience.Box {
        return Experience.Box()
    }
    
    public static func loadMenuScene() throws -> Entity {
        let sceneAnchor = AnchorEntity(.world(transform: .identity))
        
        // Add multiple floating crystals
        for i in 0..<8 {
            let crystal = Experience.Crystal()
            let angle = Float(i) * (2.0 * .pi / 8.0)
            let radius: Float = 2.0
            
            crystal.transform.translation = SIMD3<Float>(
                cos(angle) * radius,
                sin(Float(i) * 0.5),
                sin(angle) * radius
            )
            
            sceneAnchor.addChild(crystal)
        }
        
        // Add magical orbs
        for i in 0..<5 {
            let orb = Experience.MagicalOrb()
            orb.transform.translation = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -0.5...0.5),
                Float.random(in: -1...1)
            )
            
            sceneAnchor.addChild(orb)
        }
        
        // Add environment
        let environment = Experience.EnvironmentSphere()
        sceneAnchor.addChild(environment)
        
        return sceneAnchor
    }
    
    public static func loadOpenWorldEnvironment() throws -> Entity {
        let worldAnchor = AnchorEntity(.world(transform: .identity))
        
        // Create procedural environment elements
        
        // Floating energy crystals scattered throughout world
        for _ in 0..<20 {
            let crystal = Experience.Crystal()
            crystal.transform.translation = SIMD3<Float>(
                Float.random(in: -10...10),
                Float.random(in: 0.5...3.0),
                Float.random(in: -10...10)
            )
            worldAnchor.addChild(crystal)
        }
        
        // Magical essence orbs for collection
        for _ in 0..<15 {
            let orb = Experience.MagicalOrb()
            orb.transform.translation = SIMD3<Float>(
                Float.random(in: -8...8),
                1.0,
                Float.random(in: -8...8)
            )
            worldAnchor.addChild(orb)
        }
        
        // Portal markers for important locations
        for i in 0..<4 {
            let portal = Experience.Portal()
            let angle = Float(i) * (.pi / 2.0)
            portal.transform.translation = SIMD3<Float>(
                cos(angle) * 7.0,
                0.5,
                sin(angle) * 7.0
            )
            worldAnchor.addChild(portal)
        }
        
        return worldAnchor
    }
}

// MARK: - Additional Reality Composer Elements

@available(iOS 13.0, macOS 10.15, *)
extension Experience {
    
    public class Portal: Entity, HasModel, HasAnchoring {
        
        public required init() {
            super.init()
            
            // Create portal ring
            var ringMaterial = PhysicallyBasedMaterial()
            ringMaterial.baseColor = .init(tint: .blue)
            ringMaterial.emissiveColor = .init(color: .cyan)
            ringMaterial.emissiveIntensity = 2.0
            
            // Create torus for portal ring
            let ringMesh = MeshResource.generateSphere(radius: 0.8)
            self.model = ModelComponent(mesh: ringMesh, materials: [ringMaterial])
            
            self.anchoring = AnchoringComponent(.world(transform: simd_float4x4(1)))
            
            // Add rotation animation
            addPortalAnimation()
        }
        
        private func addPortalAnimation() {
            let rotation = Transform(
                scale: SIMD3<Float>(1, 1, 1),
                rotation: simd_quatf(angle: .pi * 2, axis: SIMD3<Float>(0, 1, 0)),
                translation: SIMD3<Float>(0, 0, 0)
            )
            
            let rotationAnimation = FromToByAnimation<Transform>(
                name: "portalRotation",
                by: .transform(rotation),
                duration: 4.0,
                timing: .linear,
                isAdditive: true,
                repeatMode: .loop,
                fillMode: .forwards
            )
            
            let animationController = self.playAnimation(rotationAnimation.repeat())
        }
    }
    
    public class Collectible: Entity, HasModel, HasAnchoring, HasCollision {
        
        public required init() {
            super.init()
            
            // Create collectible item
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .yellow)
            material.emissiveColor = .init(color: .orange)
            material.emissiveIntensity = 1.5
            material.metallic = .init(floatLiteral: 0.8)
            
            self.model = ModelComponent(
                mesh: .generateBox(size: [0.2, 0.2, 0.2]),
                materials: [material]
            )
            
            self.anchoring = AnchoringComponent(.world(transform: simd_float4x4(1)))
            self.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: [0.2, 0.2, 0.2])])
            
            // Add bobbing animation
            addBobAnimation()
        }
        
        private func addBobAnimation() {
            let bobUp = Transform(
                scale: SIMD3<Float>(1, 1, 1),
                rotation: simd_quatf(),
                translation: SIMD3<Float>(0, 0.1, 0)
            )
            
            let bobAnimation = FromToByAnimation<Transform>(
                name: "bob",
                by: .transform(bobUp),
                duration: 1.0,
                timing: .easeInOut,
                isAdditive: true,
                repeatMode: .autoReverse,
                fillMode: .both
            )
            
            let animationController = self.playAnimation(bobAnimation.repeat())
        }
    }
}

// MARK: - Scene Factory

@available(iOS 13.0, macOS 10.15, *)
public class RealityComposerSceneFactory {
    
    public static func createMenuScene() -> Entity {
        do {
            return try Experience.loadMenuScene()
        } catch {
            print("Failed to load menu scene: \(error)")
            return AnchorEntity(.world(transform: .identity))
        }
    }
    
    public static func createOpenWorldScene() -> Entity {
        do {
            return try Experience.loadOpenWorldEnvironment()
        } catch {
            print("Failed to load open world scene: \(error)")
            return AnchorEntity(.world(transform: .identity))
        }
    }
    
    public static func createCollectible(at position: SIMD3<Float>) -> Experience.Collectible {
        let collectible = Experience.Collectible()
        collectible.transform.translation = position
        return collectible
    }
    
    public static func createPortal(at position: SIMD3<Float>) -> Experience.Portal {
        let portal = Experience.Portal()
        portal.transform.translation = position
        return portal
    }
}

#else
// Fallback for platforms without RealityKit
@available(iOS 13.0, macOS 10.15, *)
public class Experience {
    public static func loadBox() throws -> Any? { return nil }
    public static func loadMenuScene() throws -> Any? { return nil }
    public static func loadOpenWorldEnvironment() throws -> Any? { return nil }
}

@available(iOS 13.0, macOS 10.15, *)
public class RealityComposerSceneFactory {
    public static func createMenuScene() -> Any? { return nil }
    public static func createOpenWorldScene() -> Any? { return nil }
    public static func createCollectible(at position: Any) -> Any? { return nil }
    public static func createPortal(at position: Any) -> Any? { return nil }
}
#endif