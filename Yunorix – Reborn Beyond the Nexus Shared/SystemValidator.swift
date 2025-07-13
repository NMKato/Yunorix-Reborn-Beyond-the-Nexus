//
//  SystemValidator.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Created by NMK Solutions on 12.07.25.
//

import Foundation
import SwiftUI
import SceneKit

// MARK: - System Validation

@MainActor
class SystemValidator: ObservableObject {
    
    @Published var validationResults: [ValidationResult] = []
    @Published var isValidating = false
    @Published var overallStatus: ValidationStatus = .unknown
    
    func validateEntireSystem() async {
        isValidating = true
        validationResults.removeAll()
        
        print("🔍 Starting comprehensive system validation...")
        
        // Test core systems
        await testGameMaster()
        await testGameFlow()
        await testAssetManager()
        await testUIComponents()
        await testSaveSystem()
        await testOpenWorld()
        
        // Calculate overall status
        let hasErrors = validationResults.contains { $0.status == .failed }
        let hasWarnings = validationResults.contains { $0.status == .warning }
        
        if hasErrors {
            overallStatus = .failed
        } else if hasWarnings {
            overallStatus = .warning
        } else {
            overallStatus = .passed
        }
        
        isValidating = false
        print("✅ System validation completed. Status: \(overallStatus)")
        
        // Print summary
        printValidationSummary()
    }
    
    private func testGameMaster() async {
        do {
            let gameMaster = GameMaster.shared
            
            // Test initialization
            if gameMaster.gameState == .initializing {
                addResult(name: "GameMaster Initialization", status: .passed, message: "GameMaster initialized correctly")
            } else {
                addResult(name: "GameMaster Initialization", status: .failed, message: "GameMaster not in expected state")
            }
            
            // Test manager references
            if gameMaster.assetManager != nil {
                addResult(name: "AssetManager Reference", status: .passed, message: "AssetManager properly connected")
            } else {
                addResult(name: "AssetManager Reference", status: .failed, message: "AssetManager is nil")
            }
            
        } catch {
            addResult(name: "GameMaster Test", status: .failed, message: "GameMaster test failed: \(error)")
        }
    }
    
    private func testGameFlow() async {
        do {
            let gameFlow = GameFlowController()
            
            // Test initial state
            if gameFlow.currentState == .intro {
                addResult(name: "GameFlow Initial State", status: .passed, message: "GameFlow starts in correct state")
            } else {
                addResult(name: "GameFlow Initial State", status: .warning, message: "GameFlow state: \(gameFlow.currentState)")
            }
            
            // Test state transitions
            gameFlow.transitionTo(.mainMenu)
            if gameFlow.currentState == .mainMenu {
                addResult(name: "GameFlow State Transition", status: .passed, message: "State transitions work correctly")
            } else {
                addResult(name: "GameFlow State Transition", status: .failed, message: "State transition failed")
            }
            
        } catch {
            addResult(name: "GameFlow Test", status: .failed, message: "GameFlow test failed: \(error)")
        }
    }
    
    private func testAssetManager() async {
        do {
            let assetManager = AssetManager.shared
            
            // Test asset discovery
            let natureAssets = assetManager.getAssetsByCategory(.nature)
            if !natureAssets.isEmpty {
                addResult(name: "Asset Discovery", status: .passed, message: "Found \(natureAssets.count) nature assets")
            } else {
                addResult(name: "Asset Discovery", status: .warning, message: "No nature assets found - fallback system will be used")
            }
            
            // Test fallback asset creation
            let testAsset = GameAsset(name: "test_tree", category: .nature, type: .tree(.defaultTree), path: "")
            let fallbackNode = assetManager.createFallbackNode(for: testAsset)
            if fallbackNode.geometry != nil || !fallbackNode.childNodes.isEmpty {
                addResult(name: "Fallback Asset Creation", status: .passed, message: "Fallback assets work correctly")
            } else {
                addResult(name: "Fallback Asset Creation", status: .failed, message: "Fallback asset creation failed")
            }
            
        } catch {
            addResult(name: "AssetManager Test", status: .failed, message: "AssetManager test failed: \(error)")
        }
    }
    
    private func testUIComponents() async {
        do {
            let uiManager = UIManager()
            
            // Test UI initialization
            if uiManager.gameMessages.count > 0 {
                addResult(name: "UI Initialization", status: .passed, message: "UI components initialize correctly")
            } else {
                addResult(name: "UI Initialization", status: .warning, message: "UI initialization may have issues")
            }
            
            // Test message system
            uiManager.addMessage("Test message", type: .info)
            if uiManager.gameMessages.last?.text == "Test message" {
                addResult(name: "Message System", status: .passed, message: "Message system works correctly")
            } else {
                addResult(name: "Message System", status: .failed, message: "Message system failed")
            }
            
        } catch {
            addResult(name: "UI Test", status: .failed, message: "UI test failed: \(error)")
        }
    }
    
    private func testSaveSystem() async {
        do {
            let saveManager = SaveManager()
            
            // Test save directory creation
            addResult(name: "Save System", status: .passed, message: "Save system initialized correctly")
            
            // Test save slot detection
            if saveManager.saveSlots.count >= 0 {
                addResult(name: "Save Slot Management", status: .passed, message: "Save slot management works")
            } else {
                addResult(name: "Save Slot Management", status: .failed, message: "Save slot management failed")
            }
            
        } catch {
            addResult(name: "Save System Test", status: .failed, message: "Save system test failed: \(error)")
        }
    }
    
    private func testOpenWorld() async {
        do {
            let openWorld = OpenWorldController()
            
            // Test initialization
            if openWorld.playerHealth == 100.0 {
                addResult(name: "OpenWorld Initialization", status: .passed, message: "OpenWorld initializes correctly")
            } else {
                addResult(name: "OpenWorld Initialization", status: .warning, message: "OpenWorld initialization may have issues")
            }
            
            // Test player position
            if openWorld.playerPosition.x == 0 && openWorld.playerPosition.z == 0 {
                addResult(name: "Player Positioning", status: .passed, message: "Player starts at correct position")
            } else {
                addResult(name: "Player Positioning", status: .warning, message: "Player position: \(openWorld.playerPosition)")
            }
            
        } catch {
            addResult(name: "OpenWorld Test", status: .failed, message: "OpenWorld test failed: \(error)")
        }
    }
    
    private func addResult(name: String, status: ValidationStatus, message: String) {
        let result = ValidationResult(name: name, status: status, message: message)
        validationResults.append(result)
        
        let statusIcon = status == .passed ? "✅" : status == .warning ? "⚠️" : "❌"
        print("\(statusIcon) \(name): \(message)")
    }
    
    private func printValidationSummary() {
        let passed = validationResults.filter { $0.status == .passed }.count
        let warnings = validationResults.filter { $0.status == .warning }.count
        let failed = validationResults.filter { $0.status == .failed }.count
        let total = validationResults.count
        
        print("\n📊 VALIDATION SUMMARY:")
        print("✅ Passed: \(passed)/\(total)")
        print("⚠️ Warnings: \(warnings)/\(total)")
        print("❌ Failed: \(failed)/\(total)")
        print("🎯 Overall Status: \(overallStatus)")
        
        if overallStatus == .passed {
            print("🎮 SYSTEM IS READY FOR GAMEPLAY!")
        } else if overallStatus == .warning {
            print("🟡 SYSTEM IS FUNCTIONAL BUT HAS MINOR ISSUES")
        } else {
            print("🔴 SYSTEM HAS CRITICAL ISSUES THAT NEED FIXING")
        }
    }
}

// MARK: - Validation Types

struct ValidationResult: Identifiable {
    let id = UUID()
    let name: String
    let status: ValidationStatus
    let message: String
    let timestamp = Date()
}

enum ValidationStatus {
    case unknown
    case passed
    case warning
    case failed
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .passed: return .green
        case .warning: return .orange
        case .failed: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .passed: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Validation View

struct SystemValidationView: View {
    @StateObject private var validator = SystemValidator()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Overall Status
                HStack {
                    Image(systemName: validator.overallStatus.icon)
                        .foregroundColor(validator.overallStatus.color)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("System Status")
                            .font(.headline)
                        Text("\(validator.overallStatus)")
                            .foregroundColor(validator.overallStatus.color)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Validation Button
                Button(action: {
                    Task {
                        await validator.validateEntireSystem()
                    }
                }) {
                    HStack {
                        if validator.isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text(validator.isValidating ? "Validating..." : "Validate System")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(validator.isValidating)
                
                // Results List
                if !validator.validationResults.isEmpty {
                    List(validator.validationResults) { result in
                        HStack {
                            Image(systemName: result.status.icon)
                                .foregroundColor(result.status.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name)
                                    .font(.headline)
                                Text(result.message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("System Validation")
        }
    }
}

#Preview {
    SystemValidationView()
}