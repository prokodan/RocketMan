//
//  GameOverScene.swift
//  RocketMan
//
//  Created by Данил Прокопенко on 23.02.2023.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {
    //MARK: - Nodes
    var starfield: SKEmitterNode!
    var scoreLabel: SKLabelNode!
    var newGameButtonNode: SKSpriteNode!
    var menuButtonNode: SKSpriteNode!
    //MARK: - Properties
    var score: Int = 0
    //MARK: - didMove
    override func didMove(to view: SKView) {
        self.run(SKAction.playSoundFileNamed("gameOver.wav", waitForCompletion: false))
        starfield = self.childNode(withName: "starfield") as? SKEmitterNode
        starfield.advanceSimulationTime(10)
        
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        scoreLabel.text = "\(score)"
        
        newGameButtonNode = childNode(withName: "newGameButton") as? SKSpriteNode
        newGameButtonNode.texture = SKTexture(imageNamed: "newGameButton")
    }
    //MARK: - Touch Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if let location = touch?.location(in: self) {
            let node = self.nodes(at: location)
            if node[0].name == "newGameButton" {
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameScene = GameScene(size: self.size)
                gameScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                gameScene.scene?.scaleMode = .aspectFill
                self.view?.presentScene(gameScene, transition: transition)
            }
        }
    }
}
