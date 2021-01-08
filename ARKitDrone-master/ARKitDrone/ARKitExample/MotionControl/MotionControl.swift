//
//  MotionControl.swift
//  WebRTC-Demo
//
//  Created by David Gunzinger on 22.04.19.
//  Copyright © 2019 Stas Seldin. All rights reserved.
//

import Foundation
import UIKit

protocol MotionControlDelegate: AnyObject {
    func motionMoved(control: MotionControl, direction: StickDirection)
    func shouldBeginRecognizing(control: MotionControl, position: CGPoint) -> Bool
    func cancelAllEvents()
}

var joystickSize: CGFloat = 200
var joyStickCircleDiameter: CGFloat = 80
var motionControlDefaultOffset = CGPoint(x: 20, y: 298)

class MotionControl: UIView, UIInputViewAudioFeedback {
    private var circle = UIView()
    var name: String = ""

    private var centerYContraint: NSLayoutConstraint?
    private var centerXContraint: NSLayoutConstraint?

    private let circleDiameter: CGFloat = joyStickCircleDiameter
    private var joystickRadius: CGFloat { return joystickSize / 2 }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: joystickSize,
                      height: joystickSize)
    }

    weak var delegate: MotionControlDelegate?
    var originalCenter: CGPoint = .zero

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear

        let joystickImageView = UIImageView(image: UIImage(named: "virtualJoystick"))
        addSubview(joystickImageView)
        let joystickCenterXConstraint = joystickImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor,
                                                                                   constant: 0)
        joystickCenterXConstraint.isActive = true
        let joystickCenterYConstraint = joystickImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor,
                                                                                   constant: 0)
        joystickCenterYConstraint.isActive = true

        circle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circle)
        update()

        circle.widthAnchor.constraint(equalToConstant: circleDiameter).isActive = true
        circle.heightAnchor.constraint(equalToConstant: circleDiameter).isActive = true

        centerXContraint = circle.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0)
        centerXContraint?.isActive = true
        centerYContraint = circle.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0)
        centerYContraint?.isActive = true

        bringSubview(toFront: circle)
    }

    private func update() {
        circle.backgroundColor = UIColor.white
        circle.alpha = 0.3
        circle.layer.cornerRadius = circleDiameter / 2
        circle.layer.borderWidth = 2
        circle.layer.borderColor = UIColor.white.cgColor

        layer.cornerRadius = joystickRadius
        invalidateIntrinsicContentSize()
    }

    func locomotion(state: UIGestureRecognizer.State, translation: CGPoint) {
        switch state {
        case .began:
            UIDevice.current.playInputClick()

        case .changed:
            var x = translation.x
            var y = translation.y

            let vlen = sqrt(pow(y, 2) + pow(x, 2))
            if vlen > joystickRadius {
                x = x / vlen * joystickRadius
                y = y / vlen * joystickRadius
            }

            centerXContraint?.constant = x
            centerYContraint?.constant = y

        default:
            UIDevice.current.playInputClick()
            centerYContraint?.constant = 0
            centerXContraint?.constant = 0
            spring { self.superview?.layoutIfNeeded() }
        }
        sendJoystickCommand()
    }

    private func sendJoystickCommand() {
        let x = Double(centerXContraint?.constant ?? 0)
        let y = -1.0 * Double(centerYContraint?.constant ?? 0)
        let normX = -1 * round(x) / Double(joystickRadius)
        let normY = round(y) / Double(joystickRadius)
        let pos = CGPoint(x: normX, y: normY)
        print(pos)
        if pos.x == -0.0 && pos.y == -0.0 {
            delegate?.cancelAllEvents()
        } else {
            delegate?.motionMoved(control:self ,direction: pos.stickDirection())
        }
    }
}

extension MotionControl: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let pos = gestureRecognizer.location(in: superview)
        return delegate?.shouldBeginRecognizing(control: self, position: pos) ?? true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let _ = gestureRecognizer.view == otherGestureRecognizer.view
        return true
    }
}

extension CGPoint {
    func stickDirection() -> StickDirection {
        if x > 0 && y > 0 {
            return .left
        } else if x < 0 && y < 0 {
            return .right
        } else if x < 0 && y > 0 {
            return .up
        } else {
            return .down
        }
    }
}


enum StickDirection {
    case left, right, up, down
}
