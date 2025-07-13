//
//  GameExtensions.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
typealias PlatformView = UIView
#elseif os(macOS)
import Cocoa
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
typealias PlatformView = NSView
#endif

// MARK: - Platform-Specific Extensions

#if os(iOS)
extension UIPanGestureRecognizer {
    convenience init(action: @escaping (UIPanGestureRecognizer) -> Void) {
        self.init()
        self.addAction(action)
    }
    
    private func addAction(_ action: @escaping (UIPanGestureRecognizer) -> Void) {
        let target = GestureTarget(action: action)
        addTarget(target, action: #selector(GestureTarget.execute(_:)))
        
        // Store target to prevent deallocation
        objc_setAssociatedObject(self, &AssociatedKeys.gestureTarget, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private struct AssociatedKeys {
        static var gestureTarget = "gestureTarget"
    }
    
    private class GestureTarget {
        let action: (UIPanGestureRecognizer) -> Void
        
        init(action: @escaping (UIPanGestureRecognizer) -> Void) {
            self.action = action
        }
        
        @objc func execute(_ gesture: UIPanGestureRecognizer) {
            action(gesture)
        }
    }
}
#endif

// MARK: - SCNVector3 Extensions

extension SCNVector3 {
    static let zero = SCNVector3(0, 0, 0)
    
    var length: Float {
        return sqrt(x*x + y*y + z*z)
    }
    
    var normalized: SCNVector3 {
        let len = length
        return len > 0 ? SCNVector3(x/len, y/len, z/len) : SCNVector3.zero
    }
    
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
        return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }
    
    func distance(to other: SCNVector3) -> Float {
        return (self - other).length
    }
}

// MARK: - Color Extensions

extension Color {
    static let gameBackground = Color.black
    static let gameAccent = Color.cyan
    static let gameSecondary = Color.purple
    static let gameSuccess = Color.green
    static let gameWarning = Color.orange
    static let gameDanger = Color.red
    
    // Health/Mana colors
    static let healthColor = Color.red
    static let manaColor = Color.blue
    static let experienceColor = Color.yellow
}

// MARK: - Animation Extensions

extension Animation {
    static let gameDefault = Animation.easeInOut(duration: 0.3)
    static let gameFast = Animation.easeInOut(duration: 0.15)
    static let gameSlow = Animation.easeInOut(duration: 0.6)
    static let gameSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Platform Compatibility - Already defined above

// MARK: - Game Constants

struct GameConstants {
    
    struct World {
        static let size: Float = 50.0
        static let playerSpeed: Float = 5.0
        static let cameraHeight: Float = 8.0
        static let cameraDistance: Float = 12.0
        static let collectionDistance: Float = 2.0
        static let enemyDetectionRange: Float = 10.0
    }
    
    struct Player {
        static let maxHealth: Float = 100.0
        static let maxMana: Float = 100.0
        static let startingHealth: Float = 100.0
        static let startingMana: Float = 100.0
        static let manaRegenRate: Float = 1.0
        static let radius: Float = 0.9
    }
    
    struct Enemy {
        static let damage: Float = 0.5
        static let speed: Float = 2.0
        static let patrolRadius: Float = 5.0
        static let attackRange: Float = 3.0
        static let health: Float = 50.0
    }
    
    struct Collectibles {
        static let manaRestore: Float = 10.0
        static let healthRestore: Float = 5.0
        static let floatHeight: Float = 0.3
        static let rotationSpeed: Double = 3.0
    }
    
    struct UI {
        static let fadeInDuration: Double = 0.5
        static let fadeOutDuration: Double = 0.3
        static let buttonPressScale: CGFloat = 0.95
        static let overlayOpacity: Double = 0.8
    }
    
    struct Performance {
        static let targetFPS: Double = 60.0
        static let maxObjects: Int = 100
        static let cullingDistance: Float = 30.0
        static let lodDistance: Float = 20.0
    }
}

// MARK: - Game Utilities

struct GameUtils {
    
    static func randomPosition(in worldSize: Float, margin: Float = 5.0) -> SCNVector3 {
        let range = worldSize / 2 - margin
        return SCNVector3(
            Float.random(in: -range...range),
            0,
            Float.random(in: -range...range)
        )
    }
    
    static func clampToWorld(_ position: SCNVector3, worldSize: Float, margin: Float = 2.0) -> SCNVector3 {
        let limit = worldSize / 2 - margin
        return SCNVector3(
            max(-limit, min(limit, position.x)),
            position.y,
            max(-limit, min(limit, position.z))
        )
    }
    
    static func interpolate(from: SCNVector3, to: SCNVector3, factor: Float) -> SCNVector3 {
        return SCNVector3(
            from.x + (to.x - from.x) * factor,
            from.y + (to.y - from.y) * factor,
            from.z + (to.z - from.z) * factor
        )
    }
    
    static func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    static func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000.0)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else {
            return String(number)
        }
    }
}

// MARK: - Sound Manager Stub

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var musicEnabled = true
    @Published var soundEffectsEnabled = true
    @Published var masterVolume: Double = 1.0
    
    private init() {}
    
    func playSound(_ soundName: String, volume: Double = 1.0) {
        guard soundEffectsEnabled else { return }
        // TODO: Implement sound playback
        print("🔊 Playing sound: \(soundName)")
    }
    
    func playMusic(_ musicName: String, loop: Bool = true) {
        guard musicEnabled else { return }
        // TODO: Implement music playback
        print("🎵 Playing music: \(musicName)")
    }
    
    func stopAllSounds() {
        // TODO: Implement stop all sounds
        print("🔇 Stopping all sounds")
    }
    
    func setMasterVolume(_ volume: Double) {
        masterVolume = max(0.0, min(1.0, volume))
        // TODO: Apply volume to all audio
    }
}

// MARK: - Game Settings (imported from GameMaster)

// MARK: - Performance Monitor

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var averageFPS: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var renderTime: Double = 0.0
    
    private var fpsHistory: [Double] = []
    private let maxHistoryCount = 60 // 1 second of history at 60fps
    
    private init() {}
    
    func updateFPS(_ fps: Double) {
        currentFPS = fps
        
        fpsHistory.append(fps)
        if fpsHistory.count > maxHistoryCount {
            fpsHistory.removeFirst()
        }
        
        averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
    }
    
    func updateMemoryUsage() {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &count) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     UnsafeMutablePointer($0).withMemoryRebound(to: integer_t.self, capacity: 1) { $0 },
                     $0)
        }
        
        if kerr == KERN_SUCCESS {
            memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
    }
    
    func updateRenderTime(_ time: Double) {
        renderTime = time * 1000.0 // Convert to milliseconds
    }
    
    var isPerformanceGood: Bool {
        return averageFPS >= 50.0 && memoryUsage < 300.0 && renderTime < 20.0
    }
}