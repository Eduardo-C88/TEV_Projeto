import Foundation
import SpriteKit

class StartScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        run(SKAction.playSoundFileNamed("Background", waitForCompletion: false))

        let titleLabel = SKLabelNode(text: "Snake Game")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 50
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        addChild(titleLabel)

        let tapLabel = SKLabelNode(text: "Tap to Start")
        tapLabel.fontName = "AvenirNext-Bold"
        tapLabel.fontSize = 36
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        addChild(tapLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 1.0)
        view?.presentScene(gameScene, transition: transition)
    }
}
