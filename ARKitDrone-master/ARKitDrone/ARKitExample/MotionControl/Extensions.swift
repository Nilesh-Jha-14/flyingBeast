//
//  Extensions.swift
//  Orca
//
//  Created by Daniel Schmid on 02.07.19.
//  Copyright © 2019 Smoca AG. All rights reserved.
//

import Foundation
/*
4 * Copyright (c) 2013-2014 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import CoreGraphics
import UIKit

extension UISpringTimingParameters {
    convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
}
extension UIView {
    func spring(animation: @escaping () -> Void,
                completion: ((UIViewAnimatingPosition) -> Void)?) {
        let timingParameters = UISpringTimingParameters(damping: 0.8, response: 0.3)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
        animator.isUserInteractionEnabled = true
        animator.addAnimations(animation)
        animator.isInterruptible = true
        if let completion = completion {
            animator.addCompletion(completion)
        }
        animator.startAnimation()
    }

    func spring(animation: @escaping () -> Void) {
        spring(animation: animation, completion: nil)
    }
}

extension CGPoint {
    /**
     * Creates a new CGPoint given a CGVector.
     */
     init(vector: CGVector) {
        self.init(x: vector.dx, y: vector.dy)
    }

    /**
     * Given an angle in radians, creates a vector of length 1.0 and returns the
     * result as a new CGPoint. An angle of 0 is assumed to point to the right.
     */
     init(angle: CGFloat) {
        self.init(x: cos(angle), y: sin(angle))
    }

    /**
     * Adds (dx, dy) to the point.
     */
     mutating func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
        x += dx
        y += dy
        return self
    }

    /**
     * Returns the length (magnitude) of the vector described by the CGPoint.
     */
     func length() -> CGFloat {
        return sqrt(x * x + y * y)
    }

    /**
     * Returns the squared length of the vector described by the CGPoint.
     */
     func lengthSquared() -> CGFloat {
        return x * x + y * y
    }

    /**
     * Normalizes the vector described by the CGPoint to length 1.0 and returns
     * the result as a new CGPoint.
     */
    func normalized() -> CGPoint {
        let len = length()
        return len > 0 ? self / len : CGPoint.zero
    }

    /**
     * Normalizes the vector described by the CGPoint to length 1.0.
     */
     mutating func normalize() -> CGPoint {
        self = normalized()
        return self
    }

    /**
     * Calculates the distance between two CGPoints. Pythagoras!
     */
     func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }

    /**
     * Returns the angle in radians of the vector described by the CGPoint.
     * The range of the angle is -π to π; an angle of 0 points to the right.
     */
     var angle: CGFloat {
        return atan2(y, x)
    }
}

/**
 * Adds two CGPoint values and returns the result as a new CGPoint.
 */
public func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

/**
 * Increments a CGPoint with the value of another.
 */
public func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}

/**
 * Adds a CGVector to this CGPoint and returns the result as a new CGPoint.
 */
public func + (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x + right.dx, y: left.y + right.dy)
}

/**
 * Increments a CGPoint with the value of a CGVector.
 */
public func += (left: inout CGPoint, right: CGVector) {
    left = left + right
}

/**
 * Subtracts two CGPoint values and returns the result as a new CGPoint.
 */
public func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

/**
 * Decrements a CGPoint with the value of another.
 */
public func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}

/**
 * Subtracts a CGVector from a CGPoint and returns the result as a new CGPoint.
 */
public func - (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x - right.dx, y: left.y - right.dy)
}

/**
 * Decrements a CGPoint with the value of a CGVector.
 */
public func -= (left: inout CGPoint, right: CGVector) {
    left = left - right
}

/**
 * Multiplies two CGPoint values and returns the result as a new CGPoint.
 */
public func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

/**
 * Multiplies a CGPoint with another.
 */
public func *= (left: inout CGPoint, right: CGPoint) {
    left = left * right
}

/**
 * Multiplies the x and y fields of a CGPoint with the same scalar value and
 * returns the result as a new CGPoint.
 */
public func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

/**
 * Multiplies the x and y fields of a CGPoint with the same scalar value.
 */
public func *= (point: inout CGPoint, scalar: CGFloat) {
    point = point * scalar
}

/**
 * Multiplies a CGPoint with a CGVector and returns the result as a new CGPoint.
 */
public func * (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x * right.dx, y: left.y * right.dy)
}

/**
 * Multiplies a CGPoint with a CGVector.
 */
public func *= (left: inout CGPoint, right: CGVector) {
    left = left * right
}

/**
 * Divides two CGPoint values and returns the result as a new CGPoint.
 */
public func / (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
}

/**
 * Divides a CGPoint by another.
 */
public func /= (left: inout CGPoint, right: CGPoint) {
    left = left / right
}

/**
 * Divides the x and y fields of a CGPoint by the same scalar value and returns
 * the result as a new CGPoint.
 */
public func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

/**
 * Divides the x and y fields of a CGPoint by the same scalar value.
 */
public func /= (point: inout CGPoint, scalar: CGFloat) {
    point = point / scalar
}

/**
 * Divides a CGPoint by a CGVector and returns the result as a new CGPoint.
 */
public func / (left: CGPoint, right: CGVector) -> CGPoint {
    return CGPoint(x: left.x / right.dx, y: left.y / right.dy)
}

/**
 * Divides a CGPoint by a CGVector.
 */
public func /= (left: inout CGPoint, right: CGVector) {
    left = left / right
}

/**
 * Performs a linear interpolation between two CGPoint values.
 */
public func lerp(start: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
    return start + (end - start) * t
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
