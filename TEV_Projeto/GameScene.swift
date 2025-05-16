import SpriteKit
import GameplayKit

struct Categoria {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let snakeHead: UInt32 = 0b1
    static let food: UInt32 = 0b10
    static let snakeBody: UInt32 = 0b100
    static let border: UInt32 = 0b1000
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var snake: [SKShapeNode] = []
    var direction = CGVector(dx: 0, dy: 0)
    var moveInterval: TimeInterval = 0.2
    var lastMoveTime: TimeInterval = 0
    var food: SKShapeNode?
    var score: Int = 0
    let scoreLabel = SKLabelNode()
    
    var playAreaFrame: CGRect = .zero
    let cellSize: CGFloat = 20

    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // 🔲 Square play area using full screen width, centered vertically
        let side = floor(size.width / cellSize) * cellSize
        let originX = (size.width - side) / 2
        let originY = (size.height - side) / 2
        playAreaFrame = CGRect(x: originX, y: originY, width: side, height: side)
        
        createBorder(frame: playAreaFrame)
        drawGrid()
        addScore()
        createSnake()
        spawnFood()
        createDirectionButtons()
    }
    
    func addScore() {
        scoreLabel.text = "Score: \(score)"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 60)
        scoreLabel.fontColor = .green
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
    }
    
    func createBorder(frame: CGRect) {
        let border = SKShapeNode(rect: frame.insetBy(dx: -2, dy: -2))
        border.strokeColor = .white
        border.lineWidth = 4
        
        border.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        border.physicsBody?.categoryBitMask = Categoria.border
        border.physicsBody?.contactTestBitMask = Categoria.snakeHead
        border.physicsBody?.collisionBitMask = Categoria.none
        border.physicsBody?.isDynamic = false
        
        addChild(border)
    }

    func drawGrid() {
        let cols = Int(playAreaFrame.width / cellSize)
        let rows = Int(playAreaFrame.height / cellSize)

        for i in 0...cols {
            let x = playAreaFrame.origin.x + CGFloat(i) * cellSize
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: playAreaFrame.origin.y))
            path.addLine(to: CGPoint(x: x, y: playAreaFrame.maxY))
            
            let line = SKShapeNode(path: path)
            line.strokeColor = .darkGray
            line.lineWidth = 0.5
            addChild(line)
        }

        for j in 0...rows {
            let y = playAreaFrame.origin.y + CGFloat(j) * cellSize
            let path = CGMutablePath()
            path.move(to: CGPoint(x: playAreaFrame.origin.x, y: y))
            path.addLine(to: CGPoint(x: playAreaFrame.maxX, y: y))
            
            let line = SKShapeNode(path: path)
            line.strokeColor = .darkGray
            line.lineWidth = 0.5
            addChild(line)
        }
    }
    
    func gridPosition(column: Int, row: Int) -> CGPoint {
        let x = CGFloat(column) * cellSize + playAreaFrame.origin.x + cellSize / 2
        let y = CGFloat(row) * cellSize + playAreaFrame.origin.y + cellSize / 2
        return CGPoint(x: x, y: y)
    }
    
    func createSnake() {
        let columns = Int(playAreaFrame.width / cellSize)
        let rows = Int(playAreaFrame.height / cellSize)
        let midColumn = columns / 2
        let midRow = rows / 2

        let aligned = gridPosition(column: midColumn, row: midRow)

        let head = SKShapeNode(rectOf: CGSize(width: cellSize - 1, height: cellSize - 1))
        head.fillColor = .green
        head.position = aligned

        head.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: cellSize, height: cellSize))
        head.physicsBody?.isDynamic = true
        head.physicsBody?.categoryBitMask = Categoria.snakeHead
        head.physicsBody?.contactTestBitMask = Categoria.food | Categoria.snakeBody | Categoria.border
        head.physicsBody?.collisionBitMask = Categoria.none
        head.physicsBody?.usesPreciseCollisionDetection = true

        addChild(head)
        snake.append(head)

        direction = CGVector(dx: cellSize, dy: 0) // Start moving right
    }
    
    func spawnFood() {
        food?.removeFromParent()
        
        let columns = Int(playAreaFrame.width / cellSize)
        let rows = Int(playAreaFrame.height / cellSize)
        
        let randomColumn = Int.random(in: 0..<columns)
        let randomRow = Int.random(in: 0..<rows)

        let position = gridPosition(column: randomColumn, row: randomRow)
        
        let node = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        node.fillColor = .red
        node.position = position
        
        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: cellSize - 1, height: cellSize - 1))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = Categoria.food
        node.physicsBody?.contactTestBitMask = Categoria.snakeHead
        node.physicsBody?.collisionBitMask = Categoria.none
        
        addChild(node)
        food = node
    }
    
    func growSnake() {
        guard let last = snake.last else { return }
        let newPart = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        newPart.fillColor = .green
        newPart.position = last.position

        addChild(newPart)
        snake.append(newPart)

        let addPhysics = SKAction.run {
            newPart.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 15, height: 15))
            newPart.physicsBody?.isDynamic = false
            newPart.physicsBody?.categoryBitMask = Categoria.snakeBody
            newPart.physicsBody?.contactTestBitMask = Categoria.snakeHead
            newPart.physicsBody?.collisionBitMask = Categoria.none
        }
        let wait = SKAction.wait(forDuration: moveInterval)
        newPart.run(SKAction.sequence([wait, addPhysics]))
    }
    
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

        if firstBody.categoryBitMask == Categoria.snakeHead {
            switch secondBody.categoryBitMask {
            case Categoria.food:
                score += 1
                scoreLabel.text = "Score: \(score)"
                spawnFood()
                growSnake()

            case Categoria.snakeBody, Categoria.border:
                gameOver()

            default:
                break
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if currentTime - lastMoveTime > moveInterval {
            moveSnake()
            lastMoveTime = currentTime
        }
    }
    
    func moveSnake() {
        guard let head = snake.first else { return }
        let newHeadPos = CGPoint(x: head.position.x + direction.dx, y: head.position.y + direction.dy)

        for i in (1..<snake.count).reversed() {
            snake[i].position = snake[i - 1].position
        }
        head.position = newHeadPos
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        for node in nodesAtPoint {
            if let name = node.name {
                switch name {
                case "up":
                    if direction.dy == 0 {
                        direction = CGVector(dx: 0, dy: cellSize)
                    }
                case "down":
                    if direction.dy == 0 {
                        direction = CGVector(dx: 0, dy: -cellSize)
                    }
                case "left":
                    if direction.dx == 0 {
                        direction = CGVector(dx: -cellSize, dy: 0)
                    }
                case "right":
                    if direction.dx == 0 {
                        direction = CGVector(dx: cellSize, dy: 0)
                    }
                default:
                    break
                }
            }
        }
    }
    
    func createDirectionButtons() {
        let buttonSize = CGSize(width: 50, height: 50)
        let padding: CGFloat = 10

        let baseY = frame.minY + 100
        let centerX = frame.midX

        let left = SKShapeNode(rectOf: buttonSize)
        left.name = "left"
        left.fillColor = .gray
        left.position = CGPoint(x: centerX - buttonSize.width - padding, y: baseY)

        let right = SKShapeNode(rectOf: buttonSize)
        right.name = "right"
        right.fillColor = .gray
        right.position = CGPoint(x: centerX + buttonSize.width + padding, y: baseY)

        let up = SKShapeNode(rectOf: buttonSize)
        up.name = "up"
        up.fillColor = .gray
        up.position = CGPoint(x: centerX, y: baseY + buttonSize.height + padding)

        let down = SKShapeNode(rectOf: buttonSize)
        down.name = "down"
        down.fillColor = .gray
        down.position = CGPoint(x: centerX, y: baseY - buttonSize.height - padding)

        addChild(left)
        addChild(right)
        addChild(up)
        addChild(down)

        let labels = [("←", left), ("→", right), ("↑", up), ("↓", down)]
        for (text, node) in labels {
            let label = SKLabelNode(text: text)
            label.fontSize = 20
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            node.addChild(label)
        }
    }

    func gameOver() {
        let gameOverScene = GameOverScene(size: self.size, score: self.score)
        gameOverScene.scaleMode = .aspectFill
        self.view?.presentScene(gameOverScene, transition: .flipVertical(withDuration: 1.0))
    }
}

