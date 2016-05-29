//
//  KnobView.swift
//  UIControls
//
//  Created by Eran Boudjnah on 27/05/2016.
//  Copyright © 2016 Mitteloupe. All rights reserved.
//

import UIKit

@IBDesignable
public class KnobView: UIControl {
	@IBInspectable
	var minTrackTint: UIColor = UIColor(red: 0.0 / 255.0, green: 122.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)

	@IBInspectable
	var maxTrackTint: UIColor = UIColor(red: 0.71, green: 0.71, blue: 0.71, alpha: 1.0)

	@IBInspectable
	var laneWidth: CGFloat = 2 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var laneShadowBlur: CGFloat = 0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var laneShadowDepth: CGFloat = 0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var laneMinAngle: Double = 0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var laneMaxAngle: Double = 360 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var hasThumb: Bool = true { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var thumbTint: UIColor = UIColor.whiteColor()

	@IBInspectable
	var thumbRadius: CGFloat = 14.0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var thumbShadowBlur: CGFloat = 4 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var thumbShadowDepth: CGFloat = 4 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var value: Float = 0.5 {
		didSet {
			if (value != cappedValue) { value = cappedValue }
			setNeedsDisplay()
			
			sendActionsForControlEvents(.ValueChanged)
		}
	}

	@IBInspectable
	var valueMinimum: Float = 0 {
		didSet { value = cappedValue; setNeedsDisplay() }
	}

	@IBInspectable
	var valueMaximum: Float = 1 { didSet { value = cappedValue; setNeedsDisplay() } }

	private var thumbLayer = CAShapeLayer()
	
	private var cappedValue: Float {
		get {
			return min(max(valueMinimum, value), valueMaximum)
		}
	}

	private var viewCenter: CGPoint {
		get {
			return convertPoint(center, fromView: superview)
		}
	}

	private var controlRadius: CGFloat {
		get {
			return min(bounds.width, bounds.height) / 2.0 - thumbRadius
		}
	}

	private var innerControlRadius: CGFloat {
		get {
			return controlRadius - laneWidth * 0.5
		}
	}
	
	private var outerControlRadius: CGFloat {
		get {
			return controlRadius + laneWidth * 0.5
		}
	}

	private var thumbAngle: Double {
		get {
			let relativeValue = (value - valueMinimum) / (valueMaximum - valueMinimum)
			return (Double(relativeValue) *
				(laneMaxAngle - laneMinAngle) + laneMinAngle) / 180.0 * M_PI + M_PI
		}
	}

	override public var center: CGPoint {
		didSet { setNeedsDisplay() }
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)

		prepare()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		prepare()
	}

	override public func prepareForInterfaceBuilder() {
		prepare()

		// Due to a bug in XCode, the shadow is misplaced in preview mode.
		thumbShadowDepth = -thumbShadowDepth * 2
		thumbShadowBlur *= 2
	}
	
	private func prepare() {
		contentMode = .Redraw
		opaque = false
		backgroundColor = .clearColor()

		setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
		setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Vertical)
		setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
		setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)

		layer.insertSublayer(thumbLayer, atIndex: 0)
	}

	override public func drawRect(rect: CGRect) {
		func getArcPath(arcCenter: CGPoint,
		                innerRadius: CGFloat,
		                outerRadius: CGFloat,
		                startAngle: CGFloat,
		                endAngle: CGFloat) -> UIBezierPath {
			let arcPath = UIBezierPath(arcCenter: arcCenter,
			                           radius: outerRadius,
			                           startAngle: startAngle,
			                           endAngle: endAngle,
			                           clockwise: true)
			
			arcPath.addArcWithCenter(viewCenter,
			                         radius: innerRadius,
			                         startAngle: endAngle,
			                         endAngle: startAngle,
			                         clockwise: false)
			arcPath.closePath()
			
			return arcPath
		}
		
		func clipPath() {
			let minAngle = CGFloat(laneMinAngle / 180.0 * M_PI + M_PI)
			let maxAngle = CGFloat(laneMaxAngle / 180.0 * M_PI + M_PI)
			let clipPath = getArcPath(viewCenter,
			                          innerRadius: CGFloat(innerControlRadius),
			                          outerRadius: CGFloat(outerControlRadius),
			                          startAngle: minAngle,
			                          endAngle: maxAngle)

			clipPath.addClip()
		}

		func drawProgress() {
			let minAngle = CGFloat(laneMinAngle / 180.0 * M_PI + M_PI)

			let progressPath = getArcPath(viewCenter,
			                              innerRadius: CGFloat(innerControlRadius),
			                              outerRadius: CGFloat(outerControlRadius),
			                              startAngle: minAngle,
			                              endAngle: CGFloat(thumbAngle))

			minTrackTint.setFill()
			progressPath.fill()
		}
		
		func setShadow(context: CGContext, depth: CGFloat, blur: CGFloat) {
			CGContextClipToRect(context, CGRectInfinite)
			CGContextSetShadow(context, CGSizeMake(0, depth), blur)
		}

		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)

		clipPath()
		
		let lanePath = UIBezierPath(arcCenter: viewCenter,
		                            radius: CGFloat(outerControlRadius),
		                            startAngle: 0,
		                            endAngle: CGFloat(M_PI * 2.0),
		                            clockwise: true)
		maxTrackTint.setFill()
		lanePath.fill()

		if (laneShadowDepth > 0) {
			setShadow(context!, depth: laneShadowDepth, blur: laneShadowBlur)
		}

		let laneShadowPath = UIBezierPath(rect: CGRectInfinite)

		laneShadowPath.addArcWithCenter(viewCenter,
		                                radius: CGFloat(outerControlRadius + 0.5),
		                                startAngle: 0,
		                                endAngle: CGFloat(M_PI * 2.0),
		                                clockwise: true)
		laneShadowPath.closePath()

		laneShadowPath.addArcWithCenter(viewCenter,
		                                radius: CGFloat(innerControlRadius - 0.5),
		                                startAngle: 0,
		                                endAngle: CGFloat(M_PI * 2.0),
		                                clockwise: true)

		laneShadowPath.usesEvenOddFillRule = true

		UIColor.blackColor().set()
		laneShadowPath.fill()

		CGContextRestoreGState(context)

		drawProgress()

		var thumbCenter = viewCenter
		thumbCenter.x += CGFloat(cos(thumbAngle)) * controlRadius
		thumbCenter.y += CGFloat(sin(thumbAngle)) * controlRadius
		
		let thumbPath = UIBezierPath(arcCenter: thumbCenter,
		                             radius: CGFloat(thumbRadius),
		                             startAngle: 0,
		                             endAngle: CGFloat(M_PI * 2.0),
		                             clockwise: true)

		if (hasThumb) {
			thumbLayer.path = thumbPath.CGPath
			thumbLayer.fillColor = thumbTint.CGColor
			
			thumbLayer.shadowColor = UIColor.blackColor().CGColor
			let shadowPath = UIBezierPath(arcCenter: thumbCenter,
			                              radius: CGFloat(thumbRadius - thumbShadowBlur / 2.0),
			                              startAngle: 0,
			                              endAngle: CGFloat(M_PI * 2.0),
			                              clockwise: true)
			
			thumbLayer.shadowPath = shadowPath.CGPath
			thumbLayer.shadowOffset = CGSize(width: 0, height: thumbShadowDepth)
			thumbLayer.shadowOpacity = 0.5
			thumbLayer.shadowRadius = thumbShadowBlur

		} else {
			thumbLayer.path = nil
			thumbLayer.shadowPath = nil
		}
	}

	override public func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
		if (hasThumb) {
			let location = touch.locationInView(self)
			
			setValueByPosition(location)
		}
		
		return super.beginTrackingWithTouch(touch, withEvent: event)
	}
	
	override public func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
		if (hasThumb) {
			let location = touch.locationInView(self)
			
			setValueByPosition(location)
			
			return true

		} else {
			return super.continueTrackingWithTouch(touch, withEvent: event)
		}
	}

	private func setValueByPosition(location: CGPoint) {
		let centerX = CGFloat(bounds.width / 2.0)
		let centerY = CGFloat(bounds.height / 2.0)
		var angle = (Double(atan2(location.x - centerX, location.y - centerY)) / M_PI * 180.0 + laneMinAngle) + 180
		angle = (90 - angle) % 360
		while (angle < 0) { angle += 360 }

		let targetValue = Float(angle / (laneMaxAngle - laneMinAngle)) * (valueMaximum - valueMinimum) + valueMinimum
		value = targetValue
		
		// If out of bounds, set to the closest bound.
		if (targetValue != value) {
			var dist1 = abs(angle)
			var dist2 = abs(angle - (laneMaxAngle - laneMinAngle))
			if (dist1 > 180) { dist1 = 360 - dist1 }
			if (dist2 > 180) { dist2 = 360 - dist2 }
			if (dist1 <= dist2) {
				value = valueMinimum
			} else {
				value = valueMaximum
			}
		}
	}
}
