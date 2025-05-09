import SpriteKit
import GameplayKit

struct Categoria {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let snakeHead: UInt32 = 0b1
    static let food: UInt32 = 0b10
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var snake: [SKShapeNode] = []
    var direction = CGVector(dx: 20, dy: 0)
    var moveInterval: TimeInterval = 0.2
    var lastMoveTime: TimeInterval = 0
    var food: SKShapeNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        createSnake()
        spawnFood()
    }
    
    func createSnake() {
        let head = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
        head.fillColor = .green
        head.position = CGPoint(x: frame.midX, y: frame.midY)
        
        head.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 20))
        head.physicsBody?.isDynamic = true
        head.physicsBody?.categoryBitMask = Categoria.snakeHead
        head.physicsBody?.contactTestBitMask = Categoria.food
        head.physicsBody?.collisionBitMask = Categoria.none
        head.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(head)
        snake.append(head)
    }
    
    func spawnFood() {
        food?.removeFromParent()
        
        let cellSize: CGFloat = 20
        let columns = Int(self.size.width / cellSize)
        let rows = Int(self.size.height / cellSize)
        
        let randomX = CGFloat(Int.random(in: 0..<columns)) * cellSize
        let randomY = CGFloat(Int.random(in: 0..<rows)) * cellSize
        
        let node = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        node.fillColor = .red
        node.position = CGPoint(x: randomX, y: randomY)
        
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
        
        if firstBody.categoryBitMask == Categoria.snakeHead && secondBody.categoryBitMask == Categoria.food {
            print("Snake ate food!")
            spawnFood()
            growSnake()
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
        
        // Check wall collision
        if newHeadPos.x < 0 || newHeadPos.x >= size.width ||
            newHeadPos.y < 0 || newHeadPos.y >= size.height {
            gameOver()
            return
        }
        
        // Check self-collision
        for i in 1..<snake.count {
            if snake[i].position == newHeadPos {
                gameOver()
                return
            }
        }
        
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
            direction = location.x > head.position.x ? CGVector(dx: 20, dy: 0) : CGVector(dx: -20, dy: 0)
        } else {
            // Vertical
            direction = location.y > head.position.y ? CGVector(dx: 0, dy: 20) : CGVector(dx: 0, dy: -20)
        }
    }
    
    func gameOver() {
        print("Game Over")
        removeAllChildren()
        snake.removeAll()
        createSnake()
        spawnFood()
    }
}
