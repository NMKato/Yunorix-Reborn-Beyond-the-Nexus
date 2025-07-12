//
//  IntroScreen.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Created by NMK Solutions on 12.07.25.
//

import SwiftUI
import SceneKit

struct IntroScreen: View {
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var animationComplete = false
    @State private var logoRotation: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var glowIntensity: Double = 0.5
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay {
                // Floating particles effect
                GeometryReader { geometry in
                    ForEach(0..<20, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: CGFloat.random(in: 2...6))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .animation(
                                .easeInOut(duration: Double.random(in: 2...4))
                                .repeatForever(autoreverses: true),
                                value: showLogo
                            )
                    }
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Game Logo
                VStack(spacing: 20) {
                    // Mystical symbol/logo
                    Image(systemName: "sparkles")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(logoRotation))
                        .scaleEffect(showLogo ? 1.0 : 0.1)
                        .opacity(showLogo ? 1.0 : 0.0)
                        .shadow(color: .cyan.opacity(glowIntensity), radius: 20)
                        .animation(.spring(response: 1.5, dampingFraction: 0.6), value: showLogo)
                    
                    // Game Title
                    VStack(spacing: 10) {
                        Text("YUNORIX")
                            .font(.custom("Avenir Next", size: 48))
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(titleOpacity)
                            .shadow(color: .cyan.opacity(0.8), radius: 10)
                        
                        Text("Reborn Beyond the Nexus")
                            .font(.custom("Avenir Next", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(showSubtitle ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 1.0).delay(0.5), value: showSubtitle)
                    }
                }
                
                Spacer()
                
                // Loading indicator
                if !animationComplete {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                            .scaleEffect(1.2)
                        
                        Text("Initializing Open World...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .opacity(showSubtitle ? 1.0 : 0.0)
                } else {
                    // Tap to continue
                    VStack(spacing: 10) {
                        Text("Tap to Enter the Nexus")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.cyan)
                            .opacity(0.8)
                        
                        Text("▼")
                            .font(.title2)
                            .foregroundColor(.cyan)
                            .opacity(0.6)
                    }
                    .onTapGesture {
                        onComplete()
                    }
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationComplete)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startIntroAnimation()
        }
    }
    
    private func startIntroAnimation() {
        // Logo appears and rotates
        withAnimation(.easeOut(duration: 1.0)) {
            showLogo = true
        }
        
        // Continuous rotation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            logoRotation = 360
        }
        
        // Glow effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
        
        // Title fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 1.0)) {
                titleOpacity = 1.0
            }
        }
        
        // Subtitle appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSubtitle = true
        }
        
        // Complete intro
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                animationComplete = true
            }
        }
    }
}

#Preview {
    IntroScreen {
        print("Intro completed")
    }
}