//
//  AppDelegate.swift
//  Yunorix – Reborn Beyond the Nexus iOS
//
//  Created by 4Gi .tv on 12.07.25.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize the main window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create the main game flow view
        let gameFlowView = GameFlowView()
        let hostingController = UIHostingController(rootView: gameFlowView)
        
        // Configure the hosting controller
        hostingController.view.backgroundColor = UIColor.black
        
        // Set as root view controller
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
        
        // Print system info for debugging
        print("🎮 Yunorix - Reborn Beyond the Nexus")
        print("📱 Device: \(UIDevice.current.model)")
        print("📋 iOS Version: \(UIDevice.current.systemVersion)")
        print("🎯 Starting Game Flow System...")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause the game when app becomes inactive
        print("⏸️ App will resign active - pausing game")
        NotificationCenter.default.post(name: NSNotification.Name("GameShouldPause"), object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save game state when entering background
        print("💾 App entering background - saving state")
        NotificationCenter.default.post(name: NSNotification.Name("GameShouldSave"), object: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Resume game when returning to foreground
        print("▶️ App will enter foreground - preparing resume")
        NotificationCenter.default.post(name: NSNotification.Name("GameShouldResume"), object: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume active game operations
        print("🎮 App did become active - resuming game")
        NotificationCenter.default.post(name: NSNotification.Name("GameDidBecomeActive"), object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Final save before termination
        print("🛑 App will terminate - final save")
        NotificationCenter.default.post(name: NSNotification.Name("GameWillTerminate"), object: nil)
    }
}

