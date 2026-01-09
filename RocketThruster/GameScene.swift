import SpriteKit

struct Level {
    let gravity: CGVector
    let walls: [CGRect]
    let landingPad: CGRect
    let fuelPacks: [CGRect]
    let startPosition: CGPoint
    let startRotation: CGFloat
}

enum PhysicsCategory {
    static let ship: UInt32 = 1 << 0
    static let wall: UInt32 = 1 << 1
    static let landingPad: UInt32 = 1 << 2
    static let fuel: UInt32 = 1 << 3
}

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private let ship = SKSpriteNode(color: .white, size: CGSize(width: 24, height: 32))
    private var thrusting = false
    private var rotatingLeft = false
    private var rotatingRight = false
    private var fuel: CGFloat = 100
    private var lives = 3
    private var levelIndex = 0

    private let levels: [Level] = [
        Level(
            gravity: CGVector(dx: 0, dy: -1.4),
            walls: [
                CGRect(x: 0, y: 0, width: 20, height: 200),
                CGRect(x: 180, y: 0, width: 20, height: 200)
            ],
            landingPad: CGRect(x: 80, y: 10, width: 60, height: 10),
            fuelPacks: [CGRect(x: 110, y: 140, width: 16, height: 16)],
            startPosition: CGPoint(x: 100, y: 160),
            startRotation: .pi / 2
        ),
        Level(
            gravity: CGVector(dx: 0.4, dy: -1.6),
            walls: [
                CGRect(x: 0, y: 0, width: 20, height: 260),
                CGRect(x: 200, y: 40, width: 20, height: 220),
                CGRect(x: 80, y: 80, width: 80, height: 20)
            ],
            landingPad: CGRect(x: 30, y: 30, width: 50, height: 10),
            fuelPacks: [CGRect(x: 150, y: 180, width: 16, height: 16)],
            startPosition: CGPoint(x: 140, y: 220),
            startRotation: .pi / 2
        )
    ]

    private let thrustForce: CGFloat = 28
    private let rotationSpeed: CGFloat = 2.5
    private let fuelBurnRate: CGFloat = 16  // per second

    private var hudLabel: SKLabelNode!
    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        loadLevel(index: levelIndex)
        setupHUD()
    }

    private func setupHUD() {
        hudLabel?.removeFromParent()
        hudLabel = SKLabelNode(fontNamed: "Menlo")
        hudLabel.fontSize = 14
        hudLabel.horizontalAlignmentMode = .left
        hudLabel.position = CGPoint(x: 10, y: size.height - 24)
        hudLabel.zPosition = 10
        addChild(hudLabel)
        updateHUD()
    }

    private func updateHUD() {
        hudLabel.text = "Fuel: \(Int(fuel))  Lives: \(lives)  Level: \(levelIndex + 1)"
    }

    private func loadLevel(index: Int) {
        removeAllChildren()
        physicsWorld.gravity = levels[index].gravity

        for rect in levels[index].walls {
            let wall = SKSpriteNode(color: .gray, size: rect.size)
            wall.position = CGPoint(x: rect.midX, y: rect.midY)
            wall.physicsBody = SKPhysicsBody(rectangleOf: rect.size)
            wall.physicsBody?.isDynamic = false
            wall.physicsBody?.categoryBitMask = PhysicsCategory.wall
            addChild(wall)
        }

        let padRect = levels[index].landingPad
        let pad = SKSpriteNode(color: .green, size: padRect.size)
        pad.position = CGPoint(x: padRect.midX, y: padRect.midY)
        pad.physicsBody = SKPhysicsBody(rectangleOf: padRect.size)
        pad.physicsBody?.isDynamic = false
        pad.physicsBody?.categoryBitMask = PhysicsCategory.landingPad
        pad.physicsBody?.contactTestBitMask = PhysicsCategory.ship
        addChild(pad)

        for rect in levels[index].fuelPacks {
            let fuelPack = SKSpriteNode(color: .orange, size: rect.size)
            fuelPack.name = "fuel"
            fuelPack.position = CGPoint(x: rect.midX, y: rect.midY)
            fuelPack.physicsBody = SKPhysicsBody(rectangleOf: rect.size)
            fuelPack.physicsBody?.isDynamic = false
            fuelPack.physicsBody?.categoryBitMask = PhysicsCategory.fuel
            fuelPack.physicsBody?.contactTestBitMask = PhysicsCategory.ship
            addChild(fuelPack)
        }

        ship.position = levels[index].startPosition
        ship.zRotation = levels[index].startRotation
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.size)
        ship.physicsBody?.allowsRotation = true
        ship.physicsBody?.angularDamping = 0.8
        ship.physicsBody?.linearDamping = 0.3
        ship.physicsBody?.categoryBitMask = PhysicsCategory.ship
        ship.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.landingPad
        ship.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.landingPad | PhysicsCategory.fuel
        addChild(ship)

        setupHUD()
    }

    override func update(_ currentTime: TimeInterval) {
        guard let body = ship.physicsBody else { return }
        let dt = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 1.0 / 60.0
        lastUpdateTime = currentTime

        if thrusting && fuel > 0 {
            let angle = ship.zRotation + .pi / 2
            let thrustVector = CGVector(dx: cos(angle) * thrustForce, dy: sin(angle) * thrustForce)
            body.applyForce(thrustVector)
            fuel = max(0, fuel - fuelBurnRate * dt)
        }

        if rotatingLeft { ship.zRotation += rotationSpeed * dt }
        if rotatingRight { ship.zRotation -= rotationSpeed * dt }

        updateHUD()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, event: event, isDown: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, event: event, isDown: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, event: event, isDown: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, event: event, isDown: false)
    }

    private func handleTouches(_ touches: Set<UITouch>, event: UIEvent?, isDown: Bool) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let isMultiTouch = (event?.allTouches?.count ?? 0) >= 2

        if isMultiTouch {
            thrusting = isDown
        } else {
            if location.x < size.width * 0.33 {
                rotatingLeft = isDown
            } else if location.x > size.width * 0.66 {
                rotatingRight = isDown
            } else {
                thrusting = isDown
            }
        }

        if !isDown && (event?.allTouches?.isEmpty ?? true) {
            thrusting = false
            rotatingLeft = false
            rotatingRight = false
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch mask {
        case PhysicsCategory.ship | PhysicsCategory.wall:
            handleCrash()
        case PhysicsCategory.ship | PhysicsCategory.landingPad:
            handleLanding()
        case PhysicsCategory.ship | PhysicsCategory.fuel:
            handleFuelPickup(contact)
        default:
            break
        }
    }

    private func handleCrash() {
        lives -= 1
        if lives < 0 {
            resetGame()
        } else {
            reloadLevel()
        }
    }

    private func handleLanding() {
        levelIndex = (levelIndex + 1) % levels.count
        reloadLevel()
    }

    private func handleFuelPickup(_ contact: SKPhysicsContact) {
        let node = contact.bodyA.categoryBitMask == PhysicsCategory.fuel ? contact.bodyA.node : contact.bodyB.node
        node?.removeFromParent()
        fuel = min(100, fuel + 30)
    }

    private func reloadLevel() {
        loadLevel(index: levelIndex)
    }

    private func resetGame() {
        lives = 3
        fuel = 100
        levelIndex = 0
        loadLevel(index: levelIndex)
    }
}
