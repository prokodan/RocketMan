//
//  GameScene.swift
//  RocketMan
//
//  Created by Данил Прокопенко on 21.02.2023.
//

import SpriteKit
import GameplayKit
import CoreMotion
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    //MARK: - Nodes
    var audioPlayer: AVAudioPlayer?
    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var torpedoNode: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var alien: SKSpriteNode!
    //MARK: - Properties
    let alienCategory: UInt32 = 0x1 << 1
    let torpedoCategory: UInt32 = 0x1 << 0
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var gameTimer: Timer!
    var possibleAliens = ["asteroid", "station", "alien"]
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    var livesArray: [SKSpriteNode]!
    
    //MARK: - didMove
    override func didMove(to view: SKView) {
        //        self.anchorPoint = CGPoint(x: 0, y: 0) //to move axis anchor to left bottom
        //        scene?.scaleMode = .resizeFill        // if needed
        playBackgroundMusic()
        addLives()
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: UIScreen.main.bounds.minX, y: UIScreen.main.bounds.maxY)
        starfield.advanceSimulationTime(10)
        addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "spaceShip")
        player.setScale(0.5)
        player.position = CGPoint(x: 0 , y: -(UIScreen.main.bounds.height) + player.size.height * 2 )
        
        addChild(player)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        player.scene?.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position  = CGPoint(x: -(UIScreen.main.bounds.width / 2) + scoreLabel.frame.width / 4, y: self.frame.size.height / 2 - 100)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        score = 0
        
        addChild(scoreLabel)
        
        var timeInterval = 0.8
        
        if UserDefaults.standard.bool(forKey: "hard") {
            timeInterval = 0.5
        }
        
        gameTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(addAliens), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
            if let data = data {
                let acceleration = data.acceleration
                self.xAcceleration = CGFloat(acceleration.x * 0.75 + self.xAcceleration * 0.25)
            }
        }
        
    }
    //MARK: - Touch methods
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    //MARK: - Private Methods
    private func playBackgroundMusic() {
        guard let path = Bundle.main.path(forResource: "backgroundMusic", ofType: "mp3") else { return }
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.3
            audioPlayer?.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func addLives() {
        livesArray = [SKSpriteNode]()
        for live in 1...3 {
            let liveNode = SKSpriteNode(imageNamed: "spaceShip")
            liveNode.setScale(0.2)
            liveNode.position = CGPoint(x: frame.size.width / 2 - CGFloat(6 - live) * liveNode.size.width, y: frame.size.height / 2 - 100)
            addChild(liveNode)
            livesArray.append(liveNode)
        }
    }
    
    @objc
    private func addAliens() {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomPosition = GKRandomDistribution(lowestValue: -Int(UIScreen.main.bounds.width) / 2, highestValue: Int(UIScreen.main.bounds.width) / 2)
        let position = CGFloat(randomPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: frame.size.height / 2 + alien.size.height)
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = torpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        alien.setScale(0.2)
        
        addChild(alien)
        
        let durationOfAnimation: TimeInterval = 6
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -(frame.size.height / 2) - alien.size.height), duration: durationOfAnimation))
        actionArray.append(SKAction.run {
            self.run(SKAction.playSoundFileNamed("lose.wav", waitForCompletion: false))
            if self.livesArray.count > 0 {
                let liveNode = self.livesArray.first
                liveNode?.removeFromParent()
                self.livesArray.removeFirst()
                
                if self.livesArray.count == 0 {
                    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                    guard let gameOverScene = SKScene(fileNamed: "GameOverScene") as? GameOverScene else { return }
                    gameOverScene.score = self.score
                    gameOverScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    gameOverScene.scene?.scaleMode = .aspectFill
                    self.audioPlayer?.stop()
                    self.view?.presentScene(gameOverScene, transition: transition)
                }
            }
        })
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
    }
    
    private func fireTorpedo() {
        run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 40
        torpedoNode.setScale(0.2)
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.height / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = torpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        addChild(torpedoNode)
        
        let durationOfAnimation: TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height / 2 + 10), duration: durationOfAnimation))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    //MARK: - ContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & torpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(firstBody.node as! SKSpriteNode, secondBody.node as! SKSpriteNode)
        }
    }
    
    private func torpedoDidCollideWithAlien(_ torpedoNode: SKSpriteNode, _ alienNode: SKSpriteNode) {
        guard let explosion = SKEmitterNode(fileNamed: "Explosion") else { return }
        explosion.position = alienNode.position
        addChild(explosion)
        
        run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        score += 5
    }
    //MARK: - didSimulatePhysics
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        
        if player.position.x < -(self.size.width / 2) - 20 {
            player.position = CGPoint(x: (self.size.width / 2) + 20, y: player.position.y)
        } else if player.position.x > (self.size.width / 2) + 20 {
            player.position = CGPoint(x: -(self.size.width / 2) - 20, y: player.position.y)
        }
    }
}
