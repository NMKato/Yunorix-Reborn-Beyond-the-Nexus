//
//  GameViewController.swift
//  Yunorix – Reborn Beyond the Nexus macOS
//
//  Created by 4Gi .tv on 12.07.25.
//

import Cocoa
import SceneKit

class GameViewController: NSViewController {
    
    var gameView: SCNView {
        return self.view as! SCNView
    }
    
    var gameController: GameController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gameController = GameController(sceneRenderer: gameView)
        
        // Allow the user to manipulate the camera
        self.gameView.allowsCameraControl = true
        
        // Show statistics such as fps and timing information
        self.gameView.showsStatistics = true
        
        // Configure the view
        self.gameView.backgroundColor = NSColor.black
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = gameView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        self.gameView.gestureRecognizers = gestureRecognizers
    }
    
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // Highlight the clicked nodes
        let p = gestureRecognizer.location(in: gameView)
        gameController.highlightNodes(atPoint: p)
    }
    
}
