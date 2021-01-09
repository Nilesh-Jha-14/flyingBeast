//
//  SceneViewController.swift
//  ARKitExample
//
//  Created by PORIPIREDDY Sravan on 08/01/21.
//  Copyright © 2021 RubyGarage. All rights reserved.
//

import ARKit
import CoreMotion
import Combine

class SceneViewController: UIViewController {
    private var bag = Set<AnyCancellable>()
    @IBOutlet weak var motionPane1: MotionControlPane!
    @IBOutlet weak var motionPane2: MotionControlPane!

    @IBOutlet weak var motion1vertConstraint: NSLayoutConstraint!
    @IBOutlet weak var motion1horizConstraint: NSLayoutConstraint!
    @IBOutlet weak var motion2vertConstraint: NSLayoutConstraint!
    @IBOutlet weak var motion2horizConstraint: NSLayoutConstraint!

    @IBOutlet private weak var motionControl2: MotionControl!
    @IBOutlet private weak var motionControl1: MotionControl!


    
    @IBOutlet var sceneView: SCNView!
    let CategoryTree = 2
    var scene:SCNScene!

    var droneNode: SCNNode!
    var selfieStickNode:SCNNode!

    var motion = MotionHelper()
    var motionForce = SCNVector3(0, 0, 0)

    override func viewDidLoad() {
        super.viewDidLoad()

        motionPane1.reset()
        motionPane2.reset()

        hookupMotionControls()

        setupScene()
        addDrone()
        setupNodes()
    }

    private func hookupMotionControls() {
        motionPane1.motionControl = motionControl1
        motionPane1.horizConstraint = motion1horizConstraint
        motionPane1.vertConstraint = motion1vertConstraint

        motionPane2.motionControl = motionControl2
        motionPane2.horizConstraint = motion2horizConstraint
        motionPane2.vertConstraint = motion2vertConstraint
        motionPane2.motionControlAlignment = .right

        motionControl1.name = "links"
        motionControl2.name = "rechts"

        motionControl1.delegate = self
        motionControl2.delegate = self

        motionPane1.cancelledTouches.sink { [weak self] in
            self?.droneNode.removeAllActions()
        }
        .store(in: &bag)

        motionPane2.cancelledTouches.sink { [weak self] in
            self?.droneNode.removeAllActions()
        }
        .store(in: &bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    // MARK: - setup
    func setupScene(){
        sceneView.delegate = self

        //sceneView.allowsCameraControl = true
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        sceneView.scene = scene

        scene.physicsWorld.contactDelegate = self


//            let tapRecognizer = UITapGestureRecognizer()
//            tapRecognizer.numberOfTapsRequired = 1
//            tapRecognizer.numberOfTouchesRequired = 1
//
//            tapRecognizer.addTarget(self, action: #selector(GameViewController.sceneViewTapped(recognizer:)))
//            sceneView.addGestureRecognizer(tapRecognizer)

    }

    func addDrone() {
//        droneNode.loadModel()
//        droneNode.position = kStartingPosition
//        droneNode.rotation = SCNVector4Zero
//        sceneView.scene?.rootNode.addChildNode(droneNode)
    }


    func setupNodes() {
        droneNode = scene.rootNode.childNode(withName: "drone", recursively: true)!
        droneNode.physicsBody?.contactTestBitMask = CategoryTree
        selfieStickNode = scene.rootNode.childNode(withName: "selfieStick", recursively: true)!
    }


    // MARK: - actions
    @IBAction func upLongPressed() {
        let action = SCNAction.moveBy(x: 0, y: kMovingLengthPerLoop, z: 0, duration: kAnimationDurationMoving)
        execute(action: action)
    }

    @IBAction func downLongPressed() {
        let action = SCNAction.moveBy(x: 0, y: -kMovingLengthPerLoop, z: 0, duration: kAnimationDurationMoving)
        execute(action: action)
    }

    @IBAction func moveLeftLongPressed() {
        let x = -deltas().cos
        let z = deltas().sin
        moveDrone(x: x, z: z)
    }

    @IBAction func moveRightLongPressed() {
        let x = deltas().cos
        let z = -deltas().sin
        moveDrone(x: x, z: z)
    }

    @IBAction func moveForwardLongPressed() {
        let x = -deltas().sin
        let z = -deltas().cos
        moveDrone(x: x, z: z)
    }

    @IBAction func moveBackLongPressed() {
        let x = deltas().sin
        let z = deltas().cos
        moveDrone(x: x, z: z)
    }

    func rotateLeftLongPressed() {
        rotateDrone(yRadian: kRotationRadianPerLoop)
    }

    func rotateRightLongPressed() {
        rotateDrone(yRadian: -kRotationRadianPerLoop)
    }

    // MARK: - private
    private func rotateDrone(yRadian: CGFloat) {
        let action = SCNAction.rotateBy(x: 0, y: yRadian, z: 0, duration: kAnimationDurationMoving)
        execute(action: action)
    }

    private func moveDrone(x: CGFloat, z: CGFloat) {
        let action = SCNAction.moveBy(x: x, y: 0, z: z, duration: kAnimationDurationMoving)
        execute(action: action)
    }

    private func execute(action: SCNAction) {
        let loopAction = SCNAction.repeatForever(action)
        droneNode.runAction(loopAction)
//        if sender.state == .began {
//
//        } else if sender.state == .ended {
//            droneNode.removeAllActions()
//        }
    }

    private func deltas() -> (sin: CGFloat, cos: CGFloat) {
        return (sin: kMovingLengthPerLoop * CGFloat(sin(droneNode.eulerAngles.y)), cos: kMovingLengthPerLoop * CGFloat(cos(droneNode.eulerAngles.y)))
    }
}


extension SceneViewController : SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let ball = droneNode.presentation
        let ballPosition = ball.position

        let targetPosition = SCNVector3(x: ballPosition.x, y: ballPosition.y + 5, z:ballPosition.z + 5)
        var cameraPosition = selfieStickNode.position

        let camDamping:Float = 0.3

        let xComponent = cameraPosition.x * (1 - camDamping) + targetPosition.x * camDamping
        let yComponent = cameraPosition.y * (1 - camDamping) + targetPosition.y * camDamping
        let zComponent = cameraPosition.z * (1 - camDamping) + targetPosition.z * camDamping

        cameraPosition = SCNVector3(x: xComponent, y: yComponent, z: zComponent)
        selfieStickNode.position = cameraPosition


        motion.getAccelerometerData { (x, y, z) in
            self.motionForce = SCNVector3(x: x * 0.05, y:0, z: (y + 0.8) * -0.05)
        }

        //droneNode.physicsBody?.velocity += motionForce

    }


}

extension SceneViewController : SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var contactNode:SCNNode!

        if contact.nodeA.name == "drone" {
            contactNode = contact.nodeB
        }else{
            contactNode = contact.nodeA
        }

        if contactNode.physicsBody?.categoryBitMask == CategoryTree {
            contactNode.isHidden = true

//            let sawSound = sounds["saw"]!
//            droneNode.runAction(SCNAction.playAudio(sawSound, waitForCompletion: false))

            let waitAction = SCNAction.wait(duration: 15)
            let unhideAction = SCNAction.run { (node) in
                node.isHidden = false
            }

            let actionSequence = SCNAction.sequence([waitAction, unhideAction])

            contactNode.runAction(actionSequence)
        }
    }
}


class MotionHelper {

    let motionManager = CMMotionManager()

    init() {
    }

    func getAccelerometerData(interval: TimeInterval = 0.1, motionDataResults: ((_ x: Float, _ y: Float, _ z: Float) -> ())? ){

        if motionManager.isAccelerometerAvailable {

            motionManager.accelerometerUpdateInterval = interval

            motionManager.startAccelerometerUpdates(to: OperationQueue()) { (data, error) in
                if motionDataResults != nil {
                    motionDataResults!(Float(data!.acceleration.x), Float(data!.acceleration.y), Float(data!.acceleration.z))
                }
            }

        }
    }
}

extension SceneViewController: MotionControlDelegate {
    func motionMoved(control: MotionControl, direction: StickDirection) {
        // up, down, rotate
        droneNode.removeAllActions()
        if control == motionControl1 {
            switch direction {
            case .left:
                rotateLeftLongPressed()
            case .right:
                rotateRightLongPressed()
            case .up:
                upLongPressed()
            case .down:
                downLongPressed()
            }
        } else {
            switch direction {
            case .left:
                moveLeftLongPressed()
            case .right:
                moveRightLongPressed()
            case .up:
                moveForwardLongPressed()
            case .down:
                moveBackLongPressed()
            }
        }
    }


    func shouldBeginRecognizing(control: MotionControl, position: CGPoint) -> Bool {
        return true
    }

    func cancelAllEvents() {
        droneNode.removeAllActions()
    }
}

struct StickInputUpdate {
    let x1: Float?
    let y1: Float?
    let x2: Float?
    let y2: Float?
}
