//
//  MotionControlPane.swift
//  Orca
//
//  Created by Daniel Schmid on 09.07.19.
//  Copyright © 2019 Smoca AG. All rights reserved.
//

import UIKit
import Combine

class MotionControlPane: UIView, UIInputViewAudioFeedback {
    enum MotionControlAlignment {
        case left
        case right
    }

    weak var motionControl: MotionControl?

    weak var horizConstraint: NSLayoutConstraint?
    weak var vertConstraint: NSLayoutConstraint?

    var motionControlAlignment: MotionControlAlignment = .left
    // swiftlint:disable implicitly_unwrapped_optional
    private var pan: UIPanGestureRecognizer!
    // swiftlint:enable implicitly_unwrapped_optional
    private var defaultOffset = motionControlDefaultOffset
    private var initialDiff: CGPoint = .zero
    private var startPoint: CGPoint = .zero
    private var joystickRadius: CGFloat { return joystickSize / 2 }

    private var touchesBeganSinceLastMotionEnded = false
    private var touchStartCalledSinceTouchEndedCalled = false
    var cancelledTouches = PassthroughSubject<Void, Never>()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true
        backgroundColor = .clear

        pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(recognizer:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        // otherwise switching from 'touch' to 'gesture' will emit a cancelled state
        // we would then reset the controller because we assume the device was rotated or similar, which would cause the controller to flicker
        pan.cancelsTouchesInView = false
        addGestureRecognizer(pan)
    }

    @objc
    func didPan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        let radius = joystickRadius

        switch recognizer.state {
        case .began:
            guard let motionControl = motionControl else { return }
            bringSubview(toFront: motionControl)

            startPoint = recognizer.location(in: self.superview)
            motionControl.locomotion(state: recognizer.state, translation: translation)

        case .changed:
            let touch = recognizer.location(in: self.superview)
            let diff = touch - startPoint// - CGPoint(x: r, y: r)
            let deltaDrag = sqrt(pow(diff.x, 2) + pow(diff.y, 2))

            // move both circles
            // since this is the on-change, this code will only be executed if the follow mode is set to .always
            // -> don't follow otherwise
            if deltaDrag > radius {
                let deltaX = diff.x * (1 - radius / deltaDrag)
                let deltaY = diff.y * (1 - radius / deltaDrag)
                let delta = CGPoint(x: deltaX, y: deltaY)
                recognizer.setTranslation(translation - delta, in: self)
                startPoint += delta

                if let horiz = self.horizConstraint?.constant,
                    let vert = self.vertConstraint?.constant {
                    let newHoriz = motionControlAlignment == .left ? horiz + deltaX : horiz - deltaX
                    horizConstraint?.constant = newHoriz
                    vertConstraint?.constant = vert - deltaY
                }
            }
            motionControl?.locomotion(state: recognizer.state, translation: translation)

        case .ended,
             .cancelled,
             .failed:
            cancelledTouches.send()
            touchEnds()
            motionControl?.locomotion(state: recognizer.state, translation: translation)

        default:
            motionControl?.locomotion(state: recognizer.state, translation: translation)
        }
    }

    // rotation & foreground reset
    // gesture recognizer doesn't trigger when it hasn't been activates yet...
    // touchesCancelled seems to be called when switching from 'touch' to 'swipe'
    // -> wow...
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEnds()
    }

    // callers:
    // override func touchesBegan for when the user taps the screen but doesn't move -> no gesture triggered
    // gestureRecognizer: when swiping from the display border, touchesBegan is never called
    func touchBegins(location: CGPoint) {
        if touchStartCalledSinceTouchEndedCalled {
            return
        }

        touchStartCalledSinceTouchEndedCalled = true
        guard let motionControl = motionControl,
            let horizConstraint = horizConstraint,
            let vertConstraint = vertConstraint else {
                return
        }
        motionControl.originalCenter = CGPoint(x: horizConstraint.constant,
                                               y: vertConstraint.constant)

        // when swiping in from the right side, location.x is twice as big as when clicking on any point on the right side of the screen -> I assume that, for some reason, the whole screenwidth is taken instead of that on the half pane (WHY?)
        // so if the location.x is bigger than the pane is actually wide, then divide it by 2
        let base: CGFloat = motionControlAlignment == .left ?
            location.x :
            (location.x > bounds.width ? bounds.width - location.x / 2 : bounds.width - location.x)
        let horiz = base - joystickRadius
        let vert = bounds.height - location.y - joystickRadius

        // could also leave this as it is, then the position of the controllers would be where the user
        // first clicked and never change...
        // move the whole controller
        horizConstraint.constant = horiz
        vertConstraint.constant = vert

        spring {
            self.layoutIfNeeded()
        }
    }

    func reset() {
        touchEnds()
    }

    // NOTE for .never: when the user touches the display above the motion-control, the inner
    //      dot needs to jump to the top of the outer circle immediately
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        // make it disapear when not here
        touchesBeganSinceLastMotionEnded = true
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchBegins(location: CGPoint(x: location.x, y: location.y))
    }

    func touchEnds() {
        guard let motionControl = motionControl,
            let horizConstraint = horizConstraint,
            let vertConstraint = vertConstraint else {
                return
        }
        horizConstraint.constant = defaultOffset.x
        vertConstraint.constant = defaultOffset.y

        spring {
            self.layoutIfNeeded()
        }

        touchesBeganSinceLastMotionEnded = false
        touchStartCalledSinceTouchEndedCalled = false
    }

    func cancelPanGesture() {
        pan.state = .cancelled
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchEnds()
    }
}

extension MotionControlPane: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return motionControl?.gestureRecognizerShouldBegin(gestureRecognizer) ?? true
    }
}
