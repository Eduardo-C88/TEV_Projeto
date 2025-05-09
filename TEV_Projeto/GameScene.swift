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
    var direction = CGVector(dx: 20, dy: 0)
    var moveInterval: TimeInterval = 0.2
    var lastMoveTime: TimeInterval = 0
    var food: SKShapeNode?
    
    var playAreaFrame: CGRect = .zero
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        let side = min(size.width, size.height)
        let originX = (size.width - side) / 2
        let originY = (size.height - side) / 2
        playAreaFrame = CGRect(x: originX, y: originY, width: side, height: side)
        
        createBorder(frame: playAreaFrame)
        createSnake()
        spawnFood()
    }
    
    func createBorder(frame: CGRect) {
        let border = SKShapeNode(rect: frame)
        border.strokeColor = .white
        border.lineWidth = 4
        
        border.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        border.physicsBody?.categoryBitMask = Categoria.border
        border.physicsBody?.contactTestBitMask = Categoria.snakeHead
        border.physicsBody?.collisionBitMask = Categoria.none
        border.physicsBody?.isDynamic = false
        
        addChild(border)
    }
    
    func createSnake() {
        let head = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
        head.fillColor = .green
        head.position = CGPoint(x: frame.midX, y: frame.midY)
        
        head.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 15, height: 15))
        head.physicsBody?.isDynamic = true
        head.physicsBody?.categoryBitMask = Categoria.snakeHead
        head.physicsBody?.contactTestBitMask = Categoria.food | Categoria.snakeBody | Categoria.border
        head.physicsBody?.collisionBitMask = Categoria.none
        head.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(head)
        snake.append(head)
    }
    
    func spawnFood() {
        food?.removeFromParent()
        
        let cellSize: CGFloat = 20
        let columns = Int(playAreaFrame.width / cellSize)
        let rows = Int(playAreaFrame.height / cellSize)
        
        let randomColumn = Int.random(in: 0..<columns)
        let randomRow = Int.random(in: 0..<rows)

        let x = CGFloat(randomColumn) * cellSize + playAreaFrame.origin.x + cellSize / 2
        let y = CGFloat(randomRow) * cellSize + playAreaFrame.origin.y + cellSize / 2
        
        let node = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        node.fillColor = .red
        node.position = CGPoint(x: x, y: y)
        
        node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 20))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = Categoria.food
        node.physicsBody?.contactTestBitMask = Categoria.snakeHead
        node.physicsBody?.collisionBitMask = Categoria.none
        
        addChild(node)
        food = node
    }
    
    func growSnake() {
        guard let last = snake.last else { return }
        let newPart = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
        newPart.fillColor = .green
        newPart.position = last.position

        addChild(newPart)
        snake.append(newPart)

        // Delay adding physics body to avoid immediate collision
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
                print("Snake ate food!")
                spawnFood()
                growSnake()

            case Categoria.snakeBody:
                print("Snake hit its body!")
                gameOver()

            case Categoria.border:
                print("Snake hit the wall!")
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
        
        let margin: CGFloat = 2
        let minX = playAreaFrame.minX + margin
        let maxX = playAreaFrame.maxX - 20 - margin
        let minY = playAreaFrame.minY + margin
        let maxY = playAreaFrame.maxY - 20 - margin
        
        // Move segments
        for i in (1..<snake.count).reversed() {
            snake[i].position = snake[i - 1].position
        }
        head.position = newHeadPos
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let head = snake.first!
        
        if abs(location.x - head.position.x) > abs(location.y - head.position.y) {
            // Horizontal
            let newDirection = location.x > head.position.x ? CGVector(dx: 20, dy: 0) : CGVector(dx: -20, dy: 0)
            if direction.dx == 0 { direction = newDirection }
        } else {
            // Vertical
            let newDirection = location.y > head.position.y ? CGVector(dx: 0, dy: 20) : CGVector(dx: 0, dy: -20)
            if direction.dy == 0 { direction = newDirection }
        }
    }
    
    func gameOver() {
        print("Game Over")
        removeAllChildren()
        snake.removeAll()
        createBorder(frame: playAreaFrame)
        createSnake()
        spawnFood()
    }
}
