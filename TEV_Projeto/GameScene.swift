import SpriteKit
import GameplayKit

struct Categoria {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let snakeHead: UInt32 = 0b1
    static let food: UInt32 = 0b10
    static let snakeBody: UInt32 = 0b100
    static let border: UInt32 = 0b1000
    static let powerUpSlow: UInt32 = 0b10000
    static let powerUpSpeed: UInt32 = 0b100000
    static let powerUpReverse: UInt32 = 0b1000000
    static let obstacle: UInt32 = 0b10000000
}

enum PowerUpType {
    case slow
    case speed
    case reverse
}

class PowerUp: SKShapeNode {
    let type: PowerUpType
    let duration: TimeInterval
    var activationTime: TimeInterval? = nil

    init(type: PowerUpType, cellSize: CGFloat, position: CGPoint, duration: TimeInterval = 4.0) {
        self.type = type
        self.duration = duration
        super.init()
        
        self.position = position
        
        let radius = cellSize / 2
        switch type {
        case .slow:
            self.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: cellSize, height: cellSize), transform: nil)
            self.fillColor = .blue
            
        case .speed:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: -radius, y: -radius))
            path.addLine(to: CGPoint(x: radius, y: -radius))
            path.closeSubpath()
            self.path = path
            self.fillColor = .yellow
            
        case .reverse:
            let size = CGSize(width: cellSize, height: cellSize)
            self.path = CGPath(rect: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size), transform: nil)
            self.fillColor = .purple
        }
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = {
            switch type {
            case .slow: return Categoria.powerUpSlow
            case .speed: return Categoria.powerUpSpeed
            case .reverse: return Categoria.powerUpReverse
            }
        }()
        self.physicsBody?.contactTestBitMask = Categoria.snakeHead
        self.physicsBody?.collisionBitMask = Categoria.none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyEffect(to scene: GameScene, currentTime: TimeInterval) {
        scene.powerUpActive = true
        scene.showPowerUpTimer(duration: self.duration)
        activationTime = currentTime
        switch type {
        case .slow:
            run(SKAction.playSoundFileNamed("Slow", waitForCompletion: false))
            scene.applySlowDown()
        case .speed:
            run(SKAction.playSoundFileNamed("Speed", waitForCompletion: false))
            scene.applySpeedUp()
        case.reverse:
            run(SKAction.playSoundFileNamed("Invert", waitForCompletion: false))
            scene.applyReverseControls()
        }
        scene.currentlyActivePowerUp = self
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var snake: [SKShapeNode] = []
    var direction = CGVector(dx: 0, dy: 0)
    var moveInterval: TimeInterval = 0.2
    var lastMoveTime: TimeInterval = 0
    var food: SKShapeNode?
    var score: Int = 0
    let scoreLabel = SKLabelNode()
    
    var highScore: Int = 0
    let highScoreLabel = SKLabelNode()
    
    var lastPowerUpSpawnTime: TimeInterval = 0
    var powerUpSpawnInterval: TimeInterval = 10
    var currentlyActivePowerUp: PowerUp? = nil
    var currentFrameTime: TimeInterval = 0
    
    var powerUp: SKShapeNode?
    
    var playAreaFrame: CGRect = .zero
    let cellSize: CGFloat = 20
    
    var powerUpActive = false
    var isControlsReversed = false
    var powerUpTimerBar: SKShapeNode?
    
    var obstacleSpawnInterval: TimeInterval = 8
    var lastObstacleSpawnTime: TimeInterval = 0
    var temporaryObstacles: [SKShapeNode] = []
    let obstacleDuration: TimeInterval = 6

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        let bgMusic =  SKAudioNode(fileNamed: "Background")
        bgMusic.autoplayLooped = true
        addChild(bgMusic)
        
        backgroundColor = .black
        
        highScore = UserDefaults.standard.integer(forKey: "HighScore")
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
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
        
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for dir in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = dir
            view.addGestureRecognizer(swipe)
        }
    }
    
    func showPowerUpTimer(duration: TimeInterval) {
        powerUpTimerBar?.removeFromParent()

        let barWidth = size.width * 0.6
        let barHeight: CGFloat = 10
        let bar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 5)
        bar.position = CGPoint(x: size.width / 2, y: size.height - 200)
        bar.fillColor = .white
        bar.strokeColor = .clear
        bar.zPosition = 1000
        addChild(bar)
        powerUpTimerBar = bar

        // Reset scale first
        bar.setScale(1.0)

        // Create shrink animation via xScale
        let shrink = SKAction.scaleX(to: 0.0, duration: duration)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([shrink, remove])
        bar.run(sequence)
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let multiplier: CGFloat = isControlsReversed ? -1 : 1

        switch gesture.direction {
        case .up:
            if direction.dy == 0 {
                direction = CGVector(dx: 0, dy: cellSize * multiplier)
            }
        case .down:
            if direction.dy == 0 {
                direction = CGVector(dx: 0, dy: -cellSize * multiplier)
            }
        case .left:
            if direction.dx == 0 {
                direction = CGVector(dx: -cellSize * multiplier, dy: 0)
            }
        case .right:
            if direction.dx == 0 {
                direction = CGVector(dx: cellSize * multiplier, dy: 0)
            }
        default:
            break
        }
    }
    
    func occupiedGridPositions() -> Set<NSValue> {
        var positions = Set<NSValue>()

        if let foodPosition = food?.position {
            positions.insert(NSValue(cgPoint: foodPosition))
        }

        if let powerUpPosition = powerUp?.position {
            positions.insert(NSValue(cgPoint: powerUpPosition))
        }

        for segment in snake {
            positions.insert(NSValue(cgPoint: segment.position))
        }

        for obstacle in temporaryObstacles {
            positions.insert(NSValue(cgPoint: obstacle.position))
        }

        return positions
    }
    
    func randomGridPositionAvoiding(_ positionsToAvoid: Set<NSValue>) -> CGPoint? {
        let columns = Int(playAreaFrame.width / cellSize)
        let rows = Int(playAreaFrame.height / cellSize)
        var availablePositions: [CGPoint] = []

        for col in 0..<columns {
            for row in 0..<rows {
                let pos = gridPosition(column: col, row: row)
                if !positionsToAvoid.contains(NSValue(cgPoint: pos)) {
                    availablePositions.append(pos)
                }
            }
        }

        return availablePositions.randomElement()
    }
    
    func spawnNodeAvoidingOccupied(createNode: (CGPoint) -> SKNode?) -> SKNode? {
        let occupied = occupiedGridPositions()
        guard let position = randomGridPositionAvoiding(occupied) else { return nil }
        return createNode(position)
    }
    
    func spawnTemporaryObstacle() {
        let numberOfObstacles = Int.random(in: 3...8)

        for _ in 0..<numberOfObstacles {
            guard let position = randomGridPositionAvoiding(occupiedGridPositions()) else { continue }

            let obstacleSize = CGSize(width: cellSize, height: cellSize)

            let warningNode = SKShapeNode(rectOf: obstacleSize)
            warningNode.fillColor = .red
            warningNode.alpha = 0.5
            warningNode.position = position
            warningNode.zPosition = 0.5
            addChild(warningNode)

            let blink = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.3),
                SKAction.fadeAlpha(to: 0.5, duration: 0.3)
            ])
            let blinkRepeat = SKAction.repeat(blink, count: 3)

            let spawnObstacle = SKAction.run { [weak self] in
                guard let self = self else { return }

                warningNode.removeFromParent()

                let obstacle = SKShapeNode(rectOf: obstacleSize)
                obstacle.fillColor = .brown
                obstacle.position = position
                obstacle.zPosition = 1

                obstacle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.cellSize - 1, height: self.cellSize - 1))
                obstacle.physicsBody?.isDynamic = false
                obstacle.physicsBody?.categoryBitMask = Categoria.obstacle
                obstacle.physicsBody?.contactTestBitMask = Categoria.snakeHead
                obstacle.physicsBody?.collisionBitMask = Categoria.none

                self.addChild(obstacle)
                self.temporaryObstacles.append(obstacle)

                let remove = SKAction.sequence([
                    SKAction.wait(forDuration: self.obstacleDuration),
                    SKAction.removeFromParent(),
                    SKAction.run {
                        self.temporaryObstacles.removeAll { $0 == obstacle }
                    }
                ])
                obstacle.run(remove)
            }
            warningNode.run(SKAction.sequence([blinkRepeat, spawnObstacle]))
        }
    }
    
    func addScore() {
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontName = "CourierNewPS-BoldMT"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        scoreLabel.fontColor = .green
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
        
        highScoreLabel.text = "High Score: \(highScore)"
        highScoreLabel.fontName = "CourierNewPS-BoldMT"
        highScoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        highScoreLabel.fontColor = .purple
        highScoreLabel.fontSize = 24
        addChild(highScoreLabel)
    }
    
    func createBorder(frame: CGRect) {
        let border = SKShapeNode(rect: frame.insetBy(dx: -5, dy: -4))
        border.strokeColor = .white
        border.lineWidth = 4
        
        border.physicsBody = SKPhysicsBody(edgeLoopFrom: frame.insetBy(dx: -8, dy: -8))
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
        head.physicsBody?.contactTestBitMask = Categoria.food | Categoria.snakeBody | Categoria.border | Categoria.powerUpSlow | Categoria.powerUpSpeed
        head.physicsBody?.collisionBitMask = Categoria.none
        head.physicsBody?.usesPreciseCollisionDetection = true

        addChild(head)
        snake.append(head)

        direction = CGVector(dx: cellSize, dy: 0) // Start moving right
    }
    
    func spawnFood() {
        food?.removeFromParent()
        
        if let node = spawnNodeAvoidingOccupied(createNode: { position in
            let node = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
            node.fillColor = .red
            node.position = position
            node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: cellSize - 1, height: cellSize - 1))
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = Categoria.food
            node.physicsBody?.contactTestBitMask = Categoria.snakeHead
            node.physicsBody?.collisionBitMask = Categoria.none
            return node
        }) as? SKShapeNode{
            addChild(node)
            food = node
        }
    }
    
    func spawnPowerUp() {
        if powerUpActive == false {
            powerUp?.removeFromParent()

            let typeRoll = Int.random(in: 0...2)
            let type: PowerUpType = typeRoll == 0 ? .slow : (typeRoll == 1 ? .speed : .reverse)

            if let newPowerUp = spawnNodeAvoidingOccupied(createNode: { position in
                return PowerUp(type: type, cellSize: cellSize - 1, position: position, duration: 5.0)
            }) as? PowerUp {
                addChild(newPowerUp)
                powerUp = newPowerUp
            }
        }
    }

    func randomGridPosition() -> CGPoint {
        let columns = Int(playAreaFrame.width / cellSize)
        let rows = Int(playAreaFrame.height / cellSize)
        
        let randomColumn = Int.random(in: 0..<columns)
        let randomRow = Int.random(in: 0..<rows)
        
        return gridPosition(column: randomColumn, row: randomRow)
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
        
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "HighScore")
        }
        
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
                run(SKAction.playSoundFileNamed("Food", waitForCompletion: false))
                score += 1
                scoreLabel.text = "Score: \(score)"
                spawnFood()
                growSnake()

            case Categoria.snakeBody, Categoria.border, Categoria.obstacle:
                // Try SKSequence
                run(SKAction.playSoundFileNamed("Death", waitForCompletion: false))
                gameOver()

            case Categoria.powerUpSlow, Categoria.powerUpSpeed, Categoria.powerUpReverse:
                if let power = secondBody.node as? PowerUp {
                    power.applyEffect(to: self, currentTime: currentFrameTime)
                    power.removeFromParent()
                    powerUp = nil
                }
            default:
                break
            }
        }
    }
    
    func removePowerUpEffect(type: PowerUpType) {
        powerUpActive = false
        switch type {
        case .slow, .speed:
            moveInterval = 0.2  // Reset to default
        case .reverse:
            isControlsReversed = false
        }
        powerUpTimerBar = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        currentFrameTime = currentTime

        if currentTime - lastMoveTime > moveInterval {
            moveSnake()
            lastMoveTime = currentTime
        }

        // Spawn a new power-up only if none is on the field
        if powerUp == nil && (currentTime - lastPowerUpSpawnTime) >= powerUpSpawnInterval {
            spawnPowerUp()
            lastPowerUpSpawnTime = currentTime
        }

        // Check if active power-up effect should expire
        if let activePower = currentlyActivePowerUp,
           let start = activePower.activationTime,
           currentTime - start >= activePower.duration {
            removePowerUpEffect(type: activePower.type)
            currentlyActivePowerUp = nil
        }
        
        if currentTime - lastObstacleSpawnTime >= obstacleSpawnInterval {
            spawnTemporaryObstacle()
            lastObstacleSpawnTime = currentTime
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
                let multiplier: CGFloat = isControlsReversed ? -1 : 1

                switch name {
                case "up":
                    if direction.dy == 0 {
                        direction = CGVector(dx: 0, dy: cellSize * multiplier)
                    }
                case "down":
                    if direction.dy == 0 {
                        direction = CGVector(dx: 0, dy: -cellSize * multiplier)
                    }
                case "left":
                    if direction.dx == 0 {
                        direction = CGVector(dx: -cellSize * multiplier, dy: 0)
                    }
                case "right":
                    if direction.dx == 0 {
                        direction = CGVector(dx: cellSize * multiplier, dy: 0)
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

    func applySlowDown() {
        run(SKAction.playSoundFileNamed("Slow", waitForCompletion: true))
        moveInterval *= 1.5  // Increase the interval to slow down the snake
        lastMoveTime = currentFrameTime    // Reset the last move time to reflect the change
    }

    func applySpeedUp() {
        run(SKAction.playSoundFileNamed("Speed", waitForCompletion: true))
        moveInterval *= 0.8  // Decrease the interval to speed up the snake
        lastMoveTime = currentFrameTime    // Reset the last move time to reflect the change
    }
    
    func applyReverseControls() {
        run(SKAction.playSoundFileNamed("Invert", waitForCompletion: true))
        isControlsReversed = true
        lastMoveTime = currentFrameTime
    }

    func gameOver() {
        run(SKAction.playSoundFileNamed("Death", waitForCompletion: true))
        let gameOverScene = GameOverScene(size: size, score: score)
        gameOverScene.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 1.0)
        view?.presentScene(gameOverScene, transition: transition)
    }
}
