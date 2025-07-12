//
//  AppIconGenerator.swift
//  Yunorix – Reborn Beyond the Nexus
//
//  Simple App Icon Generator Script
//

import UIKit
import SwiftUI

class AppIconGenerator {
    
    static func generateAppIcon(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background gradient
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [
                                        UIColor.black.cgColor,
                                        UIColor.purple.cgColor,
                                        UIColor.blue.cgColor,
                                        UIColor.cyan.cgColor
                                    ] as CFArray,
                                    locations: [0.0, 0.3, 0.7, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size.width, y: size.height),
                                               options: [])
            
            // Add sparkle symbol
            let symbolSize = size.width * 0.6
            let symbolRect = CGRect(
                x: (size.width - symbolSize) / 2,
                y: (size.height - symbolSize) / 2,
                width: symbolSize,
                height: symbolSize
            )
            
            // Draw sparkle/star shape
            let path = UIBezierPath()
            let center = CGPoint(x: symbolRect.midX, y: symbolRect.midY)
            let radius = symbolSize / 3
            
            // Create 8-pointed star
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                let outerRadius = (i % 2 == 0) ? radius : radius * 0.5
                let x = center.x + cos(angle) * outerRadius
                let y = center.y + sin(angle) * outerRadius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.close()
            
            // Fill star with white
            UIColor.white.setFill()
            path.fill()
            
            // Add glow effect
            context.cgContext.setBlendMode(.screen)
            UIColor.cyan.withAlphaComponent(0.8).setFill()
            path.fill()
            
            // Add game title if icon is large enough
            if size.width >= 512 {
                let titleFont = UIFont.boldSystemFont(ofSize: size.width * 0.08)
                let title = "YUNORIX"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.white,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -2
                ]
                
                let titleSize = title.size(withAttributes: titleAttributes)
                let titleRect = CGRect(
                    x: (size.width - titleSize.width) / 2,
                    y: size.height * 0.8,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                title.draw(in: titleRect, withAttributes: titleAttributes)
            }
        }
    }
    
    static func generateAllIcons() {
        let iconSizes: [CGSize] = [
            CGSize(width: 20, height: 20),   // iPhone Notification
            CGSize(width: 29, height: 29),   // iPhone Settings
            CGSize(width: 40, height: 40),   // iPhone Spotlight
            CGSize(width: 58, height: 58),   // iPhone Settings @2x
            CGSize(width: 60, height: 60),   // iPhone App @3x
            CGSize(width: 80, height: 80),   // iPhone Spotlight @2x
            CGSize(width: 87, height: 87),   // iPhone Settings @3x
            CGSize(width: 120, height: 120), // iPhone App @2x
            CGSize(width: 180, height: 180), // iPhone App @3x
            CGSize(width: 1024, height: 1024) // App Store
        ]
        
        for size in iconSizes {
            if let icon = generateAppIcon(size: size) {
                print("Generated icon: \(Int(size.width))x\(Int(size.height))")
                // In a real implementation, save the icon to the appropriate location
                // saveIcon(icon, size: size)
            }
        }
    }
}

// MARK: - Quick Icon Creation for Testing

extension UIImage {
    static func createQuickAppIcon(size: CGSize = CGSize(width: 1024, height: 1024)) -> UIImage? {
        return AppIconGenerator.generateAppIcon(size: size)
    }
}