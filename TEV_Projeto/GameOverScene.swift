import SpriteKit

class GameOverScene: SKScene {
    
    let score: Int
    
    init(size: CGSize, score: Int) {
        self.score = score
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let message = "Game Over"
        let label = SKLabelNode(text: message)
        label.fontName = "Arial-BoldMT"
        label.fontSize = 40
        label.fontColor = .red
        label.numberOfLines = 1
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
        
        let scoreText = "Score: \(score)"
        let scoreLabel = SKLabelNode(text: scoreText)
        scoreLabel.fontName = "Arial"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .green
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        addChild(scoreLabel)
        
        let retryLabel = SKLabelNode(text: "Tap to Play Again")
        retryLabel.fontName = "Arial"
        retryLabel.fontSize = 24
        retryLabel.fontColor = .gray
        retryLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        addChild(retryLabel)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let newScene = GameScene(size: size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: .doorsCloseVertical(withDuration: 1.0))
    }
}
