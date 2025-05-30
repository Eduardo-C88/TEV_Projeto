import SpriteKit

class GameOverScene: SKScene {
    
    let score: Int
    private var startButton: SKLabelNode!
    
    init(size: CGSize, score: Int) {
        self.score = score
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        //run(SKAction.playSoundFileNamed("Background", waitForCompletion: false))
        
        let bgMusic =  SKAudioNode(fileNamed: "GOBackground")
        bgMusic.autoplayLooped = true
        addChild(bgMusic)
        
        let message = "Game Over"
        let label = SKLabelNode(text: message)
        label.fontName = "Arial-BoldMT"
        label.fontSize = 40
        label.fontColor = .red
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
        
        let scoreText = "Score: \(score)"
        let scoreLabel = SKLabelNode(text: scoreText)
        scoreLabel.fontName = "Arial"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .green
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        scoreLabel.verticalAlignmentMode = .center
        addChild(scoreLabel)
        
        let retryLabel = SKLabelNode(text: "Tap to Play Again")
        retryLabel.fontName = "Arial"
        retryLabel.fontSize = 24
        retryLabel.fontColor = .gray
        retryLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        retryLabel.verticalAlignmentMode = .center
        addChild(retryLabel)
        
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        retryLabel.run(SKAction.repeatForever(pulse))
        
        // Create the Start Menu button
        startButton = SKLabelNode(text: "Go to Start Menu")
        startButton.fontName = "Arial-BoldMT"
        startButton.fontSize = 28
        startButton.fontColor = .cyan
        startButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        startButton.name = "startButton"  // Important for touch detection
        addChild(startButton)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        // Check if Start Menu button was tapped
        if nodesAtPoint.contains(where: { $0.name == "startButton" }) {
            let startScene = StartScene(size: size)
            startScene.scaleMode = .aspectFill
            view?.presentScene(startScene, transition: .doorsOpenHorizontal(withDuration: 1.0))
            return
        }
        
        // Otherwise, tap anywhere else restarts the game
        let newScene = GameScene(size: size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: .doorsCloseVertical(withDuration: 1.0))
    }
}
