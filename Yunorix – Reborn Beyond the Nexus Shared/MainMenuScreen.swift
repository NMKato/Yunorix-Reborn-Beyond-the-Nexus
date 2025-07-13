//
//  MainMenuScreen.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

#if canImport(RealityKit)
import RealityKit
#endif

struct MainMenuScreen: View {
    @State private var selectedTab = 0
    @State private var showingNewGame = false
    @State private var showingCharacterSelection = false
    @State private var showingSettings = false
    @State private var showingCredits = false
    @State private var backgroundRotation: Double = 0
    @State private var particleOffset: CGFloat = 0
    
    let onStartGame: () -> Void
    let onLoadGame: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated 3D Background
                backgroundView
                
                // Main Menu Content
                VStack(spacing: 0) {
                    // Header with logo
                    headerView
                    
                    Spacer()
                    
                    // Menu Options
                    menuOptionsView
                    
                    Spacer()
                    
                    // Footer
                    footerView
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startBackgroundAnimation()
        }
        .sheet(isPresented: $showingCharacterSelection) {
            CharacterSelectionView(onCharacterSelected: { character in
                // Start game with selected character
                onStartGame()
            })
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingCredits) {
            CreditsView()
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color.purple.opacity(0.4),
                    Color.blue.opacity(0.3),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Reality Composer Scene Background
            #if canImport(RealityKit)
            RealityKitView()
                .opacity(0.6)
                .blur(radius: 1)
            #else
            // Fallback gradient background
            LinearGradient(
                colors: [.clear, .purple.opacity(0.2), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.6)
            #endif
            
            // Floating particles
            particleSystemView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 15) {
            // Logo
            Image(systemName: "sparkles")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(backgroundRotation))
                .shadow(color: .cyan, radius: 15)
            
            // Title
            VStack(spacing: 5) {
                Text("YUNORIX")
                    .font(.custom("Avenir Next", size: 36))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Open World Adventure")
                    .font(.custom("Avenir Next", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Menu Options
    private var menuOptionsView: some View {
        VStack(spacing: 25) {
            // New Game
            MenuButton(
                title: "New Adventure",
                subtitle: "Begin your journey in the open world",
                icon: "plus.circle.fill",
                color: .green
            ) {
                showingCharacterSelection = true
            }
            
            // Continue Game
            MenuButton(
                title: "Continue Journey", 
                subtitle: "Resume your last adventure",
                icon: "play.circle.fill",
                color: .blue
            ) {
                onLoadGame()
            }
            
            // Free Roam Mode
            MenuButton(
                title: "Free Exploration",
                subtitle: "Explore the world without objectives",
                icon: "globe.europe.africa.fill",
                color: .purple
            ) {
                // Start in exploration mode
                onStartGame()
            }
            
            // Settings
            MenuButton(
                title: "Settings",
                subtitle: "Configure graphics and controls",
                icon: "gear.circle.fill",
                color: .orange
            ) {
                showingSettings = true
            }
            
            // Credits
            MenuButton(
                title: "Credits",
                subtitle: "Meet the development team",
                icon: "person.2.circle.fill",
                color: .pink
            ) {
                showingCredits = true
            }
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("v1.0 Alpha")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            Text("Open World RPG")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Particle System
    private var particleSystemView: some View {
        GeometryReader { geometry in
            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 1...4))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width) + particleOffset,
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .animation(
                        .linear(duration: Double.random(in: 3...8))
                        .repeatForever(autoreverses: false),
                        value: particleOffset
                    )
            }
        }
    }
    
    private func startBackgroundAnimation() {
        // Rotate logo continuously
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            backgroundRotation = 360
        }
        
        // Move particles
        withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
            particleOffset = 100
        }
    }
}

// MARK: - Menu Button Component
struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            action()
        }
    }
}

// MARK: - RealityKit View for 3D Background
#if canImport(RealityKit)
struct RealityKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Load Reality Composer scene
        #if canImport(RealityKit) && !DEBUG
        do {
            let box = try Experience.loadBox()
            arView.scene.anchors.append(box)
        } catch {
            print("Failed to load RealityKit scene: \(error)")
        }
        #endif
        
        // Add environmental lighting
        arView.environment.lighting.intensityExponent = 0.25
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField]
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update if needed
    }
}
#endif

// MARK: - Supporting Views
struct CharacterSelectionView: View {
    let onCharacterSelected: (HeroClass) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Choose Your Hero")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    CharacterCard(
                        name: "Mage",
                        description: "Master of arcane arts",
                        icon: "sparkles",
                        color: .purple
                    ) {
                        onCharacterSelected(.mage)
                        dismiss()
                    }
                    
                    CharacterCard(
                        name: "Warrior",
                        description: "Melee combat specialist",
                        icon: "shield.fill",
                        color: .red
                    ) {
                        onCharacterSelected(.warrior)
                        dismiss()
                    }
                    
                    CharacterCard(
                        name: "Rogue",
                        description: "Stealth and agility expert",
                        icon: "eye.slash.fill",
                        color: .green
                    ) {
                        onCharacterSelected(.rogue)
                        dismiss()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Character Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct CharacterCard: View {
    let name: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Graphics") {
                    HStack {
                        Text("Quality")
                        Spacer()
                        Picker("Quality", selection: .constant("High")) {
                            Text("Low").tag("Low")
                            Text("Medium").tag("Medium")
                            Text("High").tag("High")
                            Text("Ultra").tag("Ultra")
                        }
                    }
                }
                
                Section("Audio") {
                    Toggle("Music", isOn: .constant(true))
                    Toggle("Sound Effects", isOn: .constant(true))
                }
                
                Section("Controls") {
                    Toggle("Invert Camera", isOn: .constant(false))
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        Slider(value: .constant(0.5))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Text("YUNORIX")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 15) {
                        Text("Development Team")
                            .font(.headline)
                        
                        Text("Game Design & Programming")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("NMK Solutions")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 15) {
                        Text("Special Thanks")
                            .font(.headline)
                        
                        Text("Built with Apple's Reality Composer\nSceneKit & RealityKit\nSwiftUI Framework")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

enum HeroClass {
    case mage, warrior, rogue
}

#Preview {
    MainMenuScreen(
        onStartGame: { print("Start Game") },
        onLoadGame: { print("Load Game") }
    )
}