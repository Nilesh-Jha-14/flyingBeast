//
//  SceneViewController.swift
//  ARKitExample
//
//  Created by PORIPIREDDY Sravan on 08/01/21.
//  Copyright © 2021 RubyGarage. All rights reserved.
//

import ARKit
import CoreMotion

//let kStartingPosition = SCNVector3(0, 0, -0.6)
//let kAnimationDurationMoving: TimeInterval = 0.2
//let kMovingLengthPerLoop: CGFloat = 0.5
//let kRotationRadianPerLoop: CGFloat = 0.2

let kStartingPosition = SCNVector3(0, 0, 0.6)
let kAnimationDurationMoving: TimeInterval = 0.2
let kMovingLengthPerLoop: CGFloat = 0.5
let kRotationRadianPerLoop: CGFloat = 0.2

class SceneViewController: UIViewController {
    @IBOutlet var sceneView: SCNView!
    let CategoryTree = 2
    var scene:SCNScene!

    var droneNode = Drone()
    var selfieStickNode:SCNNode!

    var motion = MotionHelper()
    var motionForce = SCNVector3(0, 0, 0)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupScene()
        addDrone()
        setupNodes()
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
        droneNode.loadModel()
        droneNode.position = kStartingPosition
        droneNode.rotation = SCNVector4Zero
        sceneView.scene?.rootNode.addChildNode(droneNode)
    }


    func setupNodes() {
        //droneNode = scene.rootNode.childNode(withName: "ball", recursively: true)!
        droneNode.physicsBody?.contactTestBitMask = CategoryTree
        selfieStickNode = scene.rootNode.childNode(withName: "selfieStick", recursively: true)!
    }


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

        if contact.nodeA.name == "ball" {
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
