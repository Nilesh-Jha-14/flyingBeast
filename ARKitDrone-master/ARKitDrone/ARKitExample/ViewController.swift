//
//  ViewController.swift
//  ARKitExample
//
//  Created by Evgeniy Antonov on 9/5/17.
//  Copyright © 2017 RubyGarage. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit

let kStartingPosition = SCNVector3(0, 5, 0)
let kAnimationDurationMoving: TimeInterval = 0.2
let kMovingLengthPerLoop: CGFloat = 0.2
let kRotationRadianPerLoop: CGFloat = 0.2


class ViewController: UIViewController {
    @IBOutlet var mainSceneView: UIView!
    @IBOutlet var leftStickView: UIView!
    @IBOutlet var rightStickView: UIView!
    let BitMaskPig = 1
    let BitMaskVehicle = 2
    let BitMaskObstacle = 4
    let BitMaskFront = 8
    let BitMaskBack = 16
    let BitMaskLeft = 32
    let BitMaskRight = 64
    let BitMaskCoin = 128
    let BitMaskHouse = 256

    
    @IBOutlet weak var upButtonLeftSide: UIButton!
    @IBOutlet weak var bottomButtonLeftSide: UIButton!
    @IBOutlet weak var rightButtonLeftSide: UIButton!
    @IBOutlet weak var leftButtonLeftSide: UIButton!


    @IBOutlet weak var upButtonRightSide: UIButton!
    @IBOutlet weak var bottomButtonRightSide: UIButton!
    @IBOutlet weak var rightButtonRightSide: UIButton!
    @IBOutlet weak var leftButtonRightSide: UIButton!
    
    let game = GameHelper.sharedInstance
    var scnView: SCNView!
    var gameScene: SCNScene!
    var splashScene: SCNScene!

    var droneNode: SCNNode!
    var pigNode: SCNNode!
    var cameraNode: SCNNode!
    var cameraFollowNode: SCNNode!
    var lightFollowNode: SCNNode!
    var trafficNode: SCNNode!

    var driveLeftAction: SCNAction!
    var driveRightAction: SCNAction!

    var jumpLeftAction: SCNAction!
    var jumpRightAction: SCNAction!
    var jumpForwardAction: SCNAction!
    var jumpBackwardAction: SCNAction!

    var triggerGameOver: SCNAction!

    var collisionNode: SCNNode!
    var frontCollisionNode: SCNNode!
    var backCollisionNode: SCNNode!
    var leftCollisionNode: SCNNode!
    var rightCollisionNode: SCNNode!

    var activeCollisionsBitMask:Int = 0
    var longPress: UILongPressGestureRecognizer?
    var longPress1: UILongPressGestureRecognizer?
    var longPress2: UILongPressGestureRecognizer?
    var longPress3: UILongPressGestureRecognizer?
    var longPress4: UILongPressGestureRecognizer?
    var longPress5: UILongPressGestureRecognizer?
    var longPress6: UILongPressGestureRecognizer?
    var longPress7: UILongPressGestureRecognizer?


    override func viewDidLoad() {
        super.viewDidLoad()
        self.leftStickView.isHidden = true
        self.rightStickView.isHidden = true
        setupScenes()
        setupNodes()
        setupActions()
        //setupTraffic()
        setupGestures()
        setupSounds()
        game.state = .tapToPlay
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(upLongPressed(_:)))
        self.upButtonLeftSide.addGestureRecognizer(longPress!)

        longPress1 = UILongPressGestureRecognizer(target: self, action: #selector(downLongPressed(_:)))
        self.bottomButtonLeftSide.addGestureRecognizer(longPress1!)

        longPress2 = UILongPressGestureRecognizer(target: self, action: #selector(moveLeftLongPressed(_:)))
        self.leftButtonLeftSide.addGestureRecognizer(longPress2!)

        longPress3 = UILongPressGestureRecognizer(target: self, action: #selector(moveRightLongPressed(_:)))
        self.rightButtonLeftSide.addGestureRecognizer(longPress3!)



        longPress4 = UILongPressGestureRecognizer(target: self, action: #selector(moveForwardLongPressed(_:)))
        self.upButtonRightSide.addGestureRecognizer(longPress4!)

        longPress5 = UILongPressGestureRecognizer(target: self, action: #selector(moveBackLongPressed(_:)))
        self.bottomButtonRightSide.addGestureRecognizer(longPress5!)

        longPress6 = UILongPressGestureRecognizer(target: self, action: #selector(rotateLeftLongPressed(_:)))
        self.leftButtonRightSide.addGestureRecognizer(longPress6!)

        longPress7 = UILongPressGestureRecognizer(target: self, action: #selector(rotateRightLongPressed(_:)))
        self.rightButtonRightSide.addGestureRecognizer(longPress7!)
    }

    func setupScenes() {
        scnView = SCNView(frame: self.view.frame)
        mainSceneView.addSubview(scnView)
        gameScene = SCNScene(named: "/MrPig.scnassets/GameScene.scn")
        splashScene = SCNScene(named: "/MrPig.scnassets/SplashScene.scn")
        scnView.scene = splashScene
        scnView.delegate = self
        gameScene.physicsWorld.contactDelegate = self
    }

    func setupNodes() {
        pigNode = gameScene.rootNode.childNode(withName: "MrPig", recursively: true)!
        droneNode = gameScene.rootNode.childNode(withName: "drone", recursively: true)!
        cameraNode = gameScene.rootNode.childNode(withName: "camera", recursively: true)!
        //cameraNode.addChildNode(game.hudNode)
        cameraFollowNode = gameScene.rootNode.childNode(withName: "FollowCamera", recursively: true)!
        lightFollowNode = gameScene.rootNode.childNode(withName: "FollowLight", recursively: true)!
        trafficNode = gameScene.rootNode.childNode(withName: "Traffic", recursively: true)!

        collisionNode = gameScene.rootNode.childNode(withName: "Collision", recursively: true)!
        frontCollisionNode = gameScene.rootNode.childNode(withName: "Front", recursively: true)!
        backCollisionNode = gameScene.rootNode.childNode(withName: "Back", recursively: true)!
        leftCollisionNode = gameScene.rootNode.childNode(withName: "Left", recursively: true)!
        rightCollisionNode = gameScene.rootNode.childNode(withName: "Right", recursively: true)!

        pigNode.physicsBody?.contactTestBitMask = BitMaskVehicle | BitMaskCoin | BitMaskHouse
        droneNode.physicsBody?.contactTestBitMask = BitMaskVehicle | BitMaskCoin | BitMaskHouse
        frontCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        backCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        leftCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
        rightCollisionNode.physicsBody?.contactTestBitMask = BitMaskObstacle
    }

    func setupActions() {
        driveLeftAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(-2.0, 0, 0), duration: 1.0))
        driveRightAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(2.0, 0, 0), duration: 1.0))

        let duration = 0.2
        let bounceUpAction = SCNAction.moveBy(x: 0, y: 1.0, z: 0, duration: duration * 0.5)
        let bounceDownAction = SCNAction.moveBy(x: 0, y: -1.0, z: 0, duration: duration * 0.5)
        bounceUpAction.timingMode = .easeOut
        bounceDownAction.timingMode = .easeIn
        let bounceAction = SCNAction.sequence([bounceUpAction, bounceDownAction])
        let moveLeftAction = SCNAction.moveBy(x: -1.0, y: 0, z: 0, duration: duration)
        let moveRightAction = SCNAction.moveBy(x: 1.0, y: 0, z: 0, duration: duration)
        let moveForwardAction = SCNAction.moveBy(x: 0, y: 0, z: -1.0, duration: duration)
        let moveBackwardAction = SCNAction.moveBy(x: 0, y: 0, z: 1.0, duration: duration)
        let turnLeftAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: -90), z: 0, duration: duration, usesShortestUnitArc: true)
        let turnRightAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: 90), z: 0, duration: duration, usesShortestUnitArc: true)
        let turnForwardAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: 180), z: 0, duration: duration, usesShortestUnitArc: true)
        let turnBackwardAction = SCNAction.rotateTo(x: 0, y: convertToRadians(angle: 0), z: 0, duration: duration, usesShortestUnitArc: true)
        jumpLeftAction = SCNAction.group([turnLeftAction, bounceAction, moveLeftAction])
        jumpRightAction = SCNAction.group([turnRightAction, bounceAction, moveRightAction])
        jumpForwardAction = SCNAction.group([turnForwardAction, bounceAction, moveForwardAction])
        jumpBackwardAction = SCNAction.group([turnBackwardAction, bounceAction, moveBackwardAction])

        let spinAround = SCNAction.rotateBy(x: 0, y: convertToRadians(angle: 720), z: 0, duration: 2.0)
        let riseUp = SCNAction.moveBy(x: 0, y: 10, z: 0, duration: 2.0)
        let fadeOut = SCNAction.fadeOpacity(to: 0, duration: 2.0)
        let goodByePig = SCNAction.group([spinAround, riseUp, fadeOut])
        let gameOver = SCNAction.run { (node:SCNNode) -> Void in
            self.pigNode.position = SCNVector3(x:0, y:0, z:0)
            self.droneNode.position = SCNVector3(x:0, y:2, z:0)
            self.pigNode.opacity = 1.0
            self.startSplash()
        }
        triggerGameOver = SCNAction.sequence([goodByePig, gameOver])
    }

    func setupTraffic() {
        for node in trafficNode.childNodes {
            if node.name?.contains("Bus") == true {
                driveLeftAction.speed = 1.0
                driveRightAction.speed = 1.0
            } else {
                driveLeftAction.speed = 2.0
                driveRightAction.speed = 2.0
            }
            if node.eulerAngles.y > 0 {
                node.runAction(driveLeftAction)
            } else {
                node.runAction(driveRightAction)
            }
        }
    }

    func stopTraffic() {
        for node in trafficNode.childNodes {
            node.removeAllActions()
        }
    }

    func setupGestures() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeRight.direction = .right
        scnView.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeLeft.direction = .left
        scnView.addGestureRecognizer(swipeLeft)

        let swipeForward = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeForward.direction = .up
        scnView.addGestureRecognizer(swipeForward)

        let swipeBackward = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.handleGesture(_:)))
        swipeBackward.direction = .down
        scnView.addGestureRecognizer(swipeBackward)
    }

    @objc func handleGesture(_ sender: UISwipeGestureRecognizer) {
        guard game.state == .playing else {
            return
        }

        let activeFrontCollision = activeCollisionsBitMask & BitMaskFront == BitMaskFront
        let activeBackCollision = activeCollisionsBitMask & BitMaskBack == BitMaskBack
        let activeLeftCollision = activeCollisionsBitMask & BitMaskLeft == BitMaskLeft
        let activeRightCollision = activeCollisionsBitMask & BitMaskRight == BitMaskRight

        guard (sender.direction == .up && !activeFrontCollision) ||
                (sender.direction == .down && !activeBackCollision) ||
                (sender.direction == .left && !activeLeftCollision) ||
                (sender.direction == .right && !activeRightCollision) else {
            game.playSound(node: pigNode, name: "Blocked")
            return
        }

        switch sender.direction {
        case UISwipeGestureRecognizerDirection.up:
            pigNode.runAction(jumpForwardAction)
        case UISwipeGestureRecognizerDirection.down:
            pigNode.runAction(jumpBackwardAction)
        case UISwipeGestureRecognizerDirection.left:
            if pigNode.position.x >  -15 {
                pigNode.runAction(jumpLeftAction)
            }
        case UISwipeGestureRecognizerDirection.right:
            if pigNode.position.x < 15 {
                pigNode.runAction(jumpRightAction)
            }
        default:
            break
        }

        game.playSound(node: pigNode, name: "Jump")
    }

    func setupSounds() {
        if game.state == .tapToPlay {
            let music = SCNAudioSource(fileNamed: "MrPig.scnassets/Audio/Music.mp3")
            music!.volume = 0.3;
            let musicPlayer = SCNAudioPlayer(source: music!)
            music!.loops = true
            music!.shouldStream = true
            music!.isPositional = false
            splashScene.rootNode.addAudioPlayer(musicPlayer)
        } else if game.state == .playing {
            let traffic = SCNAudioSource(fileNamed: "MrPig.scnassets/Audio/Traffic.mp3")
            traffic!.volume = 0.3
            let trafficPlayer = SCNAudioPlayer(source: traffic!)
            traffic!.loops = true
            traffic!.shouldStream = true
            traffic!.isPositional = true
            gameScene.rootNode.addAudioPlayer(trafficPlayer)

            game.loadSound(name: "Jump", fileNamed: "MrPig.scnassets/Audio/Jump.wav")
            game.loadSound(name: "Blocked", fileNamed: "MrPig.scnassets/Audio/Blocked.wav")
            game.loadSound(name: "Crash", fileNamed: "MrPig.scnassets/Audio/Crash.wav")
            game.loadSound(name: "CollectCoin", fileNamed: "MrPig.scnassets/Audio/CollectCoin.wav")
            game.loadSound(name: "BankCoin", fileNamed: "MrPig.scnassets/Audio/BankCoin.wav")
        }
    }

    func startSplash() {
        gameScene.isPaused = true
        DispatchQueue.main.async {
            self.leftStickView.isHidden = true
            self.rightStickView.isHidden = true
        }
        let transition = SKTransition.doorsOpenVertical(withDuration: 1.0)
        scnView.present(splashScene, with: transition, incomingPointOfView: nil, completionHandler: {
            self.game.state = .tapToPlay
            self.setupSounds()
            self.splashScene.isPaused = false
        })
    }

    func startGame() {
        resetCoins()
        //setupTraffic()
        splashScene.isPaused = true
        let transition = SKTransition.doorsOpenVertical(withDuration: 1.0)
        scnView.present(gameScene, with: transition, incomingPointOfView: nil, completionHandler: {
            self.game.state = .playing
            self.setupSounds()
            self.gameScene.isPaused = false
            DispatchQueue.main.async {
                self.leftStickView.isHidden = false
                self.rightStickView.isHidden = false
            }
        })
    }

    func stopGame() {
        stopTraffic()
        game.state = .gameOver
        game.reset()
        pigNode.runAction(triggerGameOver)
    }

    func resetCoins() {
        let coinsNode = gameScene.rootNode.childNode(
            withName: "Coins", recursively: true)!
        for node in coinsNode.childNodes {
            for child in node.childNodes {
                child.isHidden = false
            }
        }
    }

    func updatePositions() {
        collisionNode.position = droneNode.position
        pigNode.position = droneNode.position

        if droneNode.position.y < 0.5 {
            droneNode.removeAllActions()
            droneNode.position.y = 0.5
        }

        let lerpX = (droneNode.position.x - cameraFollowNode.position.x) * 0.05
        let lerpZ = (droneNode.position.z - cameraFollowNode.position.z) * 0.05
        cameraFollowNode.position.x += lerpX
        cameraFollowNode.position.z += lerpZ

        lightFollowNode.position = cameraFollowNode.position
    }

    func updateTraffic() {
        for node in trafficNode.childNodes {
            if node.position.x > 25 {
                node.position.x = -25
            } else if node.position.x < -25 {
                node.position.x = 25
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if game.state == .tapToPlay {
            startGame()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var prefersStatusBarHidden : Bool { return true }

    override var shouldAutorotate : Bool { return false }

    // MARK: - actions






    @IBAction func upLongPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: 0, y: kMovingLengthPerLoop, z: 0, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }

    @IBAction func downLongPressed(_ sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: 0, y: -kMovingLengthPerLoop, z: 0, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }

    @IBAction func moveLeftLongPressed(_ sender: UILongPressGestureRecognizer) {
        let x = -deltas().cos
        let z = deltas().sin
        moveDrone(x: x, z: z, sender: sender)
    }

    @IBAction func moveRightLongPressed(_ sender: UILongPressGestureRecognizer) {
        let x = deltas().cos
        let z = -deltas().sin
        moveDrone(x: x, z: z, sender: sender)
    }

    @IBAction func moveForwardLongPressed(_ sender: UILongPressGestureRecognizer) {
        let x = -deltas().sin
        let z = -deltas().cos
        moveDrone(x: x, z: z, sender: sender)
    }

    @IBAction func moveBackLongPressed(_ sender: UILongPressGestureRecognizer) {
        let x = deltas().sin
        let z = deltas().cos
        moveDrone(x: x, z: z, sender: sender)
    }

    @IBAction func rotateLeftLongPressed(_ sender: UILongPressGestureRecognizer) {
        rotateDrone(yRadian: kRotationRadianPerLoop, sender: sender)
    }

    @IBAction func rotateRightLongPressed(_ sender: UILongPressGestureRecognizer) {
        rotateDrone(yRadian: -kRotationRadianPerLoop, sender: sender)
    }

    // MARK: - private
    private func rotateDrone(yRadian: CGFloat, sender: UILongPressGestureRecognizer) {
        let action = SCNAction.rotateBy(x: 0, y: yRadian, z: 0, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }

    private func moveDrone(x: CGFloat, z: CGFloat, sender: UILongPressGestureRecognizer) {
        let action = SCNAction.moveBy(x: x, y: 0, z: z, duration: kAnimationDurationMoving)
        execute(action: action, sender: sender)
    }

    private func execute(action: SCNAction, sender: UILongPressGestureRecognizer) {
        let loopAction = SCNAction.repeatForever(action)
        switch sender {
        case longPress:
            upButtonLeftSide.isSelected = sender.state == .began
        case longPress1:
            bottomButtonLeftSide.isSelected = sender.state == .began
        case longPress2:
            leftButtonLeftSide.isSelected = sender.state == .began
        case longPress3:
            rightButtonLeftSide.isSelected = sender.state == .began

        case longPress4:
            upButtonRightSide.isSelected = sender.state == .began
        case longPress5:
            bottomButtonRightSide.isSelected = sender.state == .began
        case longPress6:
            leftButtonRightSide.isSelected = sender.state == .began
        case longPress7:
            rightButtonRightSide.isSelected = sender.state == .began

        default :
            break
        }

        if sender.state == .began {
            droneNode.runAction(loopAction)
        } else if sender.state == .ended {
            droneNode.removeAllActions()
        }
    }

    private func deltas() -> (sin: CGFloat, cos: CGFloat) {
        return (sin: kMovingLengthPerLoop * CGFloat(sin(droneNode.eulerAngles.y)), cos: kMovingLengthPerLoop * CGFloat(cos(droneNode.eulerAngles.y)))
    }
}

extension ViewController : SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time:
                    TimeInterval) {
        guard game.state == .playing else {
            return
        }
        game.updateHUD()
        updatePositions()
        updateTraffic()
    }
}

extension ViewController : SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld,
                      didBegin contact: SCNPhysicsContact) {
        guard game.state == .playing else {
            return
        }

        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskObstacle {
            collisionBoxNode = contact.nodeB
        } else {
            collisionBoxNode = contact.nodeA
        }
        activeCollisionsBitMask |=
            collisionBoxNode.physicsBody!.categoryBitMask

        var contactNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskPig {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }

        if contactNode.physicsBody?.categoryBitMask == BitMaskVehicle ||
            contactNode.physicsBody?.categoryBitMask == BitMaskHouse {
            game.playSound(node: pigNode, name: "Crash")
            //stopGame()
            droneNode.removeAllActions()
        }

        if contactNode.physicsBody?.categoryBitMask == BitMaskCoin {
            contactNode.isHidden = true
            contactNode.runAction(SCNAction.waitForDurationThenRunBlock(duration: 60) { (node: SCNNode!) -> Void in
                node.isHidden = false
            })
            game.collectCoin()
            game.playSound(node: pigNode, name: "CollectCoin")
        }

        if contactNode.physicsBody?.categoryBitMask == BitMaskHouse {
            if game.bankCoins() == true {
                game.playSound(node: pigNode, name: "BankCoin")
            }
        }
    }

    func physicsWorld(_ world: SCNPhysicsWorld,
                      didEnd contact: SCNPhysicsContact) {
        guard game.state == .playing else {
            return
        }

        var collisionBoxNode: SCNNode!
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskObstacle {
            collisionBoxNode = contact.nodeB
        } else {
            collisionBoxNode = contact.nodeA
        }
        activeCollisionsBitMask &=
            ~collisionBoxNode.physicsBody!.categoryBitMask
    }
}
