import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Свойства
    private var platform: SKSpriteNode!
    private var ball: SKShapeNode!
    private var target: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!
    
    private var score = 0
    private var lives = 3
    private var isGameOver = false
    private var isBallOnPlatform = true
    private var touchOffset: CGFloat = 0
    
    // MARK: - Физика
    private enum PhysicsCategory {
        static let ball: UInt32 = 0x1 << 0
        static let platform: UInt32 = 0x1 << 1
        static let target: UInt32 = 0x1 << 2
        static let wall: UInt32 = 0x1 << 3
        static let bottom: UInt32 = 0x1 << 4
    }
    
    // MARK: - Жизненный цикл
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        setupBackground()
        setupPlatform()
        setupBall()
        setupWalls()
        setupLabels()
        spawnTarget()
        
        // Начальное положение мяча на платформе
        placeBallOnPlatform()
    }
    
    // MARK: - Настройка сцены
    private func setupBackground() {
        backgroundColor = .black
        
        // Добавим градиентный фон
        let gradientNode = SKShapeNode(rect: frame)
        let gradientTexture = createGradientTexture()
        gradientNode.fillTexture = gradientTexture
        gradientNode.fillColor = .clear
        gradientNode.strokeColor = .clear
        gradientNode.zPosition = -1
        addChild(gradientNode)
    }
    
    private func createGradientTexture() -> SKTexture {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return SKTexture() }
        
        let colors = [UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0).cgColor,
                      UIColor(red: 0.0, green: 0.0, blue: 0.1, alpha: 1.0).cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: nil)
        context.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image!)
    }
    
    private func setupPlatform() {
        let platformSize = CGSize(width: 150, height: 20)
        platform = SKSpriteNode(color: .white, size: platformSize)
        platform.position = CGPoint(x: frame.midX, y: 100)
        platform.name = "platform"
        
        // Добавим свечение
        let glow = SKShapeNode(rectOf: platformSize)
        glow.strokeColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.5)
        glow.lineWidth = 4
        glow.position = platform.position
        glow.name = "glow"
        addChild(glow)
        
        // Физика платформы
        platform.physicsBody = SKPhysicsBody(rectangleOf: platformSize)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.platform
        platform.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        platform.physicsBody?.collisionBitMask = PhysicsCategory.ball
        
        addChild(platform)
    }
    
    private func setupBall() {
        let ballRadius: CGFloat = 15
        ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
        ball.strokeColor = .white
        ball.lineWidth = 2
        ball.name = "ball"
        
        // Эффект свечения
        let glow = SKShapeNode(circleOfRadius: ballRadius * 1.5)
        glow.fillColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.2)
        glow.strokeColor = .clear
        glow.position = .zero
        glow.name = "ballGlow"
        ball.addChild(glow)
        
        // Физика мяча
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        ball.physicsBody?.friction = 0
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.angularDamping = 0
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.platform | PhysicsCategory.target | PhysicsCategory.wall | PhysicsCategory.bottom
        ball.physicsBody?.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.target | PhysicsCategory.wall
        
        addChild(ball)
    }
    
    private func setupWalls() {
        // Верхняя стена
        let topWall = SKNode()
        topWall.position = .zero
        topWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 1), center: CGPoint(x: frame.midX, y: frame.maxY))
        topWall.physicsBody?.isDynamic = false
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        topWall.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(topWall)
        
        // Левая стена
        let leftWall = SKNode()
        leftWall.position = .zero
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: frame.height), center: CGPoint(x: frame.minX, y: frame.midY))
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        leftWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        leftWall.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(leftWall)
        
        // Правая стена
        let rightWall = SKNode()
        rightWall.position = .zero
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: frame.height), center: CGPoint(x: frame.maxX, y: frame.midY))
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        rightWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        rightWall.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(rightWall)
        
        // Нижняя граница (для отслеживания падения)
        let bottomWall = SKNode()
        bottomWall.position = .zero
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 1), center: CGPoint(x: frame.midX, y: frame.minY - 50))
        bottomWall.physicsBody?.isDynamic = false
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.bottom
        bottomWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        bottomWall.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(bottomWall)
    }
    
    private func setupLabels() {
        // Счет
        scoreLabel = SKLabelNode(text: "Счет: 0")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 100, y: frame.maxY - 60)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        // Жизни
        livesLabel = SKLabelNode(text: "❤️ ❤️ ❤️")
        livesLabel.fontSize = 30
        livesLabel.position = CGPoint(x: frame.maxX - 100, y: frame.maxY - 60)
        livesLabel.horizontalAlignmentMode = .right
        addChild(livesLabel)
    }
    
    private func spawnTarget() {
        // Удаляем старую цель, если есть
        target?.removeFromParent()
        
        let targetSize = CGSize(width: 60, height: 60)
        target = SKSpriteNode(color: .clear, size: targetSize)
        
        // Рисуем цель в виде звезды или круга
        let shape = SKShapeNode(circleOfRadius: 25)
        shape.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 0.8)
        shape.strokeColor = .white
        shape.lineWidth = 3
        shape.name = "targetShape"
        target.addChild(shape)
        
        // Добавим пульсирующий эффект
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        shape.run(SKAction.repeatForever(pulse))
        
        // Случайная позиция в верхней части экрана
        let minX = 100
        let maxX = Int(frame.maxX - 100)
        let minY = Int(frame.midY + 100)
        let maxY = Int(frame.maxY - 150)
        
        let randomX = CGFloat(Int.random(in: minX...maxX))
        let randomY = CGFloat(Int.random(in: minY...maxY))
        
        target.position = CGPoint(x: randomX, y: randomY)
        target.name = "target"
        
        // Физика цели
        target.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        target.physicsBody?.isDynamic = false
        target.physicsBody?.categoryBitMask = PhysicsCategory.target
        target.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        target.physicsBody?.collisionBitMask = PhysicsCategory.ball
        
        addChild(target)
        
        // Добавим вращение цели
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 10)
        target.run(SKAction.repeatForever(rotate))
    }
    
    private func placeBallOnPlatform() {
        isBallOnPlatform = true
        ball.position = CGPoint(x: platform.position.x, y: platform.position.y + 25)
        ball.physicsBody?.velocity = .zero
        ball.physicsBody?.isDynamic = false
    }
    
    // MARK: - Управление
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if isGameOver {
            restartGame()
            return
        }
        
        // Проверяем, касание на платформе
        if platform.contains(location) {
            touchOffset = location.x - platform.position.x
        }
        
        // Если мяч на платформе и касание на мяче или рядом с ним
        if isBallOnPlatform {
            let distance = hypot(location.x - ball.position.x, location.y - ball.position.y)
            if distance < 100 {
                launchBall()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Двигаем платформу
        let newX = location.x - touchOffset
        let clampedX = min(max(newX, 50), frame.maxX - 50)
        platform.position.x = clampedX
        
        // Обновляем свечение
        if let glow = childNode(withName: "glow") {
            glow.position.x = clampedX
        }
        
        // Если мяч на платформе, двигаем его вместе с ней
        if isBallOnPlatform {
            ball.position.x = clampedX
        }
    }
    
    private func launchBall() {
        guard isBallOnPlatform else { return }
        
        isBallOnPlatform = false
        ball.physicsBody?.isDynamic = true
        
        // Случайный угол запуска
        let angle = CGFloat.random(in: -0.5...0.5)
        let speed: CGFloat = 400
        
        let dx = sin(angle) * speed
        let dy = cos(angle) * speed
        
        ball.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
    }
    
    // MARK: - Физика
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
        
        // Мяч столкнулся с целью
        if (firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.target) ||
           (firstBody.categoryBitMask == PhysicsCategory.target && secondBody.categoryBitMask == PhysicsCategory.ball) {
            
            // Показываем эффект попадания
            if let targetNode = firstBody.categoryBitMask == PhysicsCategory.target ? firstBody.node : secondBody.node,
               let ballNode = firstBody.categoryBitMask == PhysicsCategory.ball ? firstBody.node : secondBody.node {
                createHitEffect(at: ballNode.position)
                score += 1
                updateScore()
                spawnTarget()
                
                // Увеличиваем скорость мяча
                if let velocity = ball.physicsBody?.velocity {
                    let speed = hypot(velocity.dx, velocity.dy)
                    if speed < 800 {
                        let multiplier: CGFloat = 1.1
                        ball.physicsBody?.velocity = CGVector(dx: velocity.dx * multiplier, dy: velocity.dy * multiplier)
                    }
                }
            }
        }
        
        // Мяч упал вниз
        if (firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.bottom) ||
           (firstBody.categoryBitMask == PhysicsCategory.bottom && secondBody.categoryBitMask == PhysicsCategory.ball) {
            loseLife()
        }
        
        // Мяч отскочил от платформы
        if (firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.platform) ||
           (firstBody.categoryBitMask == PhysicsCategory.platform && secondBody.categoryBitMask == PhysicsCategory.ball) {
            // Добавляем случайность при отскоке
            if let ballBody = firstBody.categoryBitMask == PhysicsCategory.ball ? firstBody : secondBody {
                let currentVelocity = ballBody.velocity
                let randomAngle = CGFloat.random(in: -0.3...0.3)
                let speed = hypot(currentVelocity.dx, currentVelocity.dy)
                if speed > 0 {
                    let angle = atan2(currentVelocity.dy, currentVelocity.dx) + randomAngle
                    ballBody.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                }
            }
        }
    }
    
    private func createHitEffect(at position: CGPoint) {
        // Создаем частицы
        let emitter = SKEmitterNode()
        emitter.position = position
        
        // Настраиваем эмиттер
        emitter.particleBirthRate = 100
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        emitter.particleColorSequence = nil
        emitter.particleColorBlendFactor = 1.0
        
        // Добавляем на сцену
        addChild(emitter)
        
        // Удаляем через секунду
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitter.removeFromParent()
        }
    }
    
    // MARK: - Игровая логика
    private func loseLife() {
        lives -= 1
        updateLives()
        
        if lives <= 0 {
            gameOver()
        } else {
            placeBallOnPlatform()
        }
    }
    
    private func updateScore() {
        scoreLabel.text = "Счет: \(score)"
    }
    
    private func updateLives() {
        var hearts = ""
        for _ in 0..<lives {
            hearts += "❤️ "
        }
        livesLabel.text = hearts
    }
    
    private func gameOver() {
        isGameOver = true
        ball.removeFromParent()
        
        gameOverLabel = SKLabelNode(text: "ИГРА ОКОНЧЕНА")
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        addChild(gameOverLabel)
        
        let finalScoreLabel = SKLabelNode(text: "Счет: \(score)")
        finalScoreLabel.fontSize = 30
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        finalScoreLabel.name = "finalScore"
        addChild(finalScoreLabel)
        
        let restartLabel = SKLabelNode(text: "Нажмите для рестарта")
        restartLabel.fontSize = 25
        restartLabel.fontColor = .gray
        restartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        restartLabel.name = "restartLabel"
        addChild(restartLabel)
    }
    
    private func restartGame() {
        // Удаляем старые элементы
        gameOverLabel?.removeFromParent()
        childNode(withName: "finalScore")?.removeFromParent()
        childNode(withName: "restartLabel")?.removeFromParent()
        
        // Сброс параметров
        score = 0
        lives = 3
        isGameOver = false
        
        updateScore()
        updateLives()
        
        // Восстанавливаем мяч
        setupBall()
        placeBallOnPlatform()
        spawnTarget()
    }
}

// MARK: - Расширение для SKScene
extension SKScene {
    func addGradientBackground() {
        // Вспомогательный метод для градиента
    }
}