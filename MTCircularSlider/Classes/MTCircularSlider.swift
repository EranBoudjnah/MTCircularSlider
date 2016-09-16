/**
* Copyright (c) 2016 Eran Boudjnah
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

import UIKit

//
// Attributes for configuring a MTKnobView.
//
public enum Attributes {
	/* Track */
	case minTrackTint(UIColor)
	case maxTrackTint(UIColor)
	case trackWidth(CGFloat)
	case trackShadowRadius(CGFloat)
	case trackShadowDepth(CGFloat)
	case trackMinAngle(Double)
	case trackMaxAngle(Double)
	
	/* Thumb */
	case hasThumb(Bool)
	case thumbTint(UIColor)
	case thumbRadius(CGFloat)
	case thumbShadowRadius(CGFloat)
	case thumbShadowDepth(CGFloat)
}

@IBDesignable
public class MTCircularSlider: UIControl {
	@IBInspectable
	var minTrackTint: UIColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)

	@IBInspectable
	var maxTrackTint: UIColor = UIColor(red: 0.71, green: 0.71, blue: 0.71, alpha: 1.0)
	
	@IBInspectable
	var trackWidth: CGFloat = 2 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var trackShadowRadius: CGFloat = 0 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var trackShadowDepth: CGFloat = 0 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var trackMinAngle: Double = 0.0 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var trackMaxAngle: Double = 360.0 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var hasThumb: Bool = true { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var thumbTint: UIColor = UIColor.whiteColor()
	
	@IBInspectable
	var thumbRadius: CGFloat = 14 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var thumbShadowRadius: CGFloat = 2 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	var thumbShadowDepth: CGFloat = 3 { didSet { setNeedsDisplay() } }
	
	@IBInspectable
	public var value: Float = 0.5 {
		didSet {
			let cappedVal = cappedValue(value)
			if value != cappedVal { value = cappedVal }
			setNeedsDisplay()
			
			sendActionsForControlEvents(.ValueChanged)
		}
	}
	
	@IBInspectable
	public var valueMinimum: Float = 0 {
		didSet {
			value = cappedValue(value)
			setNeedsDisplay()
		}
	}
	
	@IBInspectable
	public var valueMaximum: Float = 1 {
		didSet {
			value = cappedValue(value)
			setNeedsDisplay()
		}
	}
	
	private var thumbLayer = CAShapeLayer()
	
	private var viewCenter: CGPoint {
		return convertPoint(center, fromView: superview)
	}
	
	private var thumbCenter: CGPoint {
		var thumbCenter = viewCenter
		thumbCenter.x += CGFloat(cos(thumbAngle)) * controlRadius
		thumbCenter.y += CGFloat(sin(thumbAngle)) * controlRadius
		return thumbCenter
	}
	
	private var controlRadius: CGFloat {
		return min(bounds.width, bounds.height) / 2.0 - controlThickness
	}
	
	private var controlThickness: CGFloat {
		let thumbRadius = (hasThumb) ? self.thumbRadius : 0
		return max(thumbRadius, trackWidth / 2.0)
	}
	
	private var innerControlRadius: CGFloat {
		return controlRadius - trackWidth * 0.5
	}
	
	private var outerControlRadius: CGFloat {
		return controlRadius + trackWidth * 0.5
	}
	
	private var thumbAngle: CGFloat {
		let normalizedValue = (value - valueMinimum) / (valueMaximum - valueMinimum)
		let degrees = Double(normalizedValue) * (trackMaxAngle - trackMinAngle) +
		trackMinAngle
		// Convert to radians and rotate 180 degrees so that 0 degrees would be on
		// the left.
		let radians = degrees / 180.0 * M_PI + M_PI
		return CGFloat(radians)
	}
	
	private var lastPositionForTouch = CGPointZero
	
	private var pseudoValueForTouch = Float(0.0)
	
	override
	public var center: CGPoint {
		didSet { setNeedsDisplay() }
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		prepare()
	}
	
	required
	public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		prepare()
	}
	
	override
	public func prepareForInterfaceBuilder() {
		prepare()
		
		// Due to a bug in XCode, the shadow is misplaced in Interface Builder.
		thumbShadowDepth = -thumbShadowDepth * 2
		thumbShadowRadius *= 2
	}
	
	override
	public func drawRect(rect: CGRect) {
		/**
		Returns a UIBezierPath with the shape of a ring slice.
		
		- parameter arcCenter:   The center of the ring
		- parameter innerRadius: The inner radius of the ring
		- parameter outerRadius: The outer radius of the ring
		- parameter startAngle:  The start angle of the ring slice
		- parameter endAngle:    The end angle of the ring slice
		
		- returns: A UIBezierPath with the shape of a ring slice.
		*/
		func getArcPath(arcCenter: CGPoint, innerRadius: CGFloat,
		                outerRadius: CGFloat, startAngle: CGFloat,
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
		
		/**
		Clips the drawing to the MTCircularSlider track.
		*/
		func clipPath() {
			let minAngle = CGFloat(trackMinAngle / 180.0 * M_PI + M_PI)
			let maxAngle = CGFloat(trackMaxAngle / 180.0 * M_PI + M_PI)
			let clipPath = getArcPath(viewCenter,
			                          innerRadius: innerControlRadius,
			                          outerRadius: outerControlRadius,
			                          startAngle: minAngle,
			                          endAngle: maxAngle)
			
			clipPath.addClip()
		}
		
		/**
		Fills the part of the track between the mininum angle and the thumb.
		*/
		func drawProgress() {
			let minAngle = CGFloat(trackMinAngle / 180.0 * M_PI + M_PI)
			
			let progressPath = getArcPath(viewCenter,
			                              innerRadius: innerControlRadius,
			                              outerRadius: outerControlRadius,
			                              startAngle: minAngle,
			                              endAngle: thumbAngle)
			
			minTrackTint.setFill()
			progressPath.fill()
		}
		
		func setShadow(context: CGContext, depth: CGFloat, radius: CGFloat) {
			CGContextClipToRect(context, CGRectInfinite)
			CGContextSetShadow(context, CGSizeMake(0, depth), radius)
		}
		
		func drawTrack(context: CGContext) {
			let trackPath = circlePath(withCenter: viewCenter,
			                           radius: outerControlRadius)
			maxTrackTint.setFill()
			trackPath.fill()
			
			if trackShadowDepth > 0 {
				setShadow(context, depth: trackShadowDepth, radius: trackShadowRadius)
			}
			
			let trackShadowPath = UIBezierPath(rect: CGRectInfinite)
			
			trackShadowPath.appendPath(
				circlePath(withCenter: viewCenter,
					radius: CGFloat(outerControlRadius + 0.5))
			)
			
			trackShadowPath.closePath()
			
			trackShadowPath.appendPath(
				circlePath(withCenter: viewCenter,
					radius: CGFloat(innerControlRadius - 0.5))
			)
			
			trackShadowPath.usesEvenOddFillRule = true
			
			UIColor.blackColor().set()
			trackShadowPath.fill()
		}
		
		func drawThumb() {
			let thumbPath = circlePath(withCenter: thumbCenter,
			                           radius: thumbRadius)
			
			let thumbHasShadow = thumbShadowDepth != 0 || thumbShadowRadius != 0
			
			if hasThumb && thumbHasShadow {
				thumbLayer.path = thumbPath.CGPath
				thumbLayer.fillColor = thumbTint.CGColor
				
				thumbLayer.shadowColor = UIColor.blackColor().CGColor
				thumbLayer.shadowPath = thumbPath.CGPath
				thumbLayer.shadowOffset = CGSize(width: 0, height: thumbShadowDepth)
				thumbLayer.shadowOpacity = 0.25
				thumbLayer.shadowRadius = thumbShadowRadius
				
			} else {
				thumbLayer.path = nil
				thumbLayer.shadowPath = nil
				
				if hasThumb {
					thumbTint.setFill()
					thumbPath.fill()
				}
			}
		}
		
		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context!)
		
		clipPath()
		
		drawTrack(context!)
		
		CGContextRestoreGState(context!)
		
		drawProgress()
		
		drawThumb()
	}
	
	override
	public func beginTrackingWithTouch(touch: UITouch,
	                                   withEvent event: UIEvent?) -> Bool {
		if hasThumb {
			let location = touch.locationInView(self)
			
			let pseudoValue = calculatePseudoValue(at: location)
			// Check if the touch is out of our bounds.
			if cappedValue(pseudoValue) != pseudoValue {
				// If the touch is on the thumb, start dragging from the thumb.
				if locationOnThumb(location) {
					lastPositionForTouch = location
					calculatePseudoValue(at: thumbCenter)
					return true
					
				} else {
					// Not on thumb or track, so abort gesture.
					return false
				}
			}
			
			value = pseudoValue
			lastPositionForTouch = location
		}
		
		return super.beginTrackingWithTouch(touch, withEvent: event)
	}
	
	override
	public func continueTrackingWithTouch(touch: UITouch,
	                                      withEvent event: UIEvent?) -> Bool {
		if !hasThumb {
			return super.continueTrackingWithTouch(touch, withEvent: event)
		}
		
		let location = touch.locationInView(self)
		
		value = calculatePseudoValue(from: lastPositionForTouch, to: location)
		
		lastPositionForTouch = location
		
		return true
	}
	
	// Iterate over the provided attributes and set the corresponding values.
	public func configure(attributes: [Attributes]) {
		for attribute in attributes {
			switch attribute {
				/* Track */
			case let .minTrackTint(value):
				self.minTrackTint = value
			case let .maxTrackTint(value):
				self.maxTrackTint = value
			case let .trackWidth(value):
				self.trackWidth = value
			case let .trackShadowRadius(value):
				self.trackShadowRadius = value
			case let .trackShadowDepth(value):
				self.trackShadowDepth = value
			case let .trackMinAngle(value):
				self.trackMinAngle = value
			case let .trackMaxAngle(value):
				self.trackMaxAngle = value
				
				/* Thumb */
			case let .hasThumb(value):
				self.hasThumb = value
			case let .thumbTint(value):
				self.thumbTint = value
			case let .thumbRadius(value):
				self.thumbRadius = value
			case let .thumbShadowRadius(value):
				self.thumbShadowRadius = value
			case let .thumbShadowDepth(value):
				self.thumbShadowDepth = value
			}
		}
		
		setNeedsDisplay()
	}
	
	private func prepare() {
		contentMode = .Redraw
		opaque = false
		backgroundColor = .clearColor()
		
		layer.insertSublayer(thumbLayer, atIndex: 0)
	}
	
	private func cappedValue(value: Float) -> Float {
		return min(max(valueMinimum, value), valueMaximum)
	}
	
	private func circlePath(withCenter center: CGPoint,
	                                   radius: CGFloat) -> UIBezierPath {
		return UIBezierPath(arcCenter: center,
		                    radius: radius,
		                    startAngle: 0,
		                    endAngle: CGFloat(M_PI * 2.0),
		                    clockwise: true)
	}
	
	// True if the provided location is on the thumb, false otherwise.
	private func locationOnThumb(location: CGPoint) -> Bool {
		let thumbCenter = self.thumbCenter
		return sqrt(pow(location.x - thumbCenter.x, 2) +
			pow(location.y - thumbCenter.y, 2)) <= thumbRadius
	}
	
	private func calculatePseudoValue(at point: CGPoint) -> Float {
		let angle = angleAt(point)
		
		// Normalize the angle, then convert to value scale.
		let targetValue =
			Float(angle / (trackMaxAngle - trackMinAngle)) *
				(valueMaximum - valueMinimum) + valueMinimum
		
		pseudoValueForTouch = targetValue
		
		return targetValue
	}
	
	private func calculatePseudoValue(from from: CGPoint, to: CGPoint) -> Float {
		let angle1 = angleAt(from)
		let angle2 = angleAt(to)
		var angle = angle2 - angle1
		let valueRange = valueMaximum - valueMinimum
		let angleToValue =
			Double(valueRange) / (trackMaxAngle - trackMinAngle)
		let clockwise = isClockwise(
			vector1: CGPoint(x: from.x - bounds.midX, y: from.y - bounds.midY),
			vector2: CGPoint(x: to.x - from.x, y: to.y - from.y)
		)
		
		if (clockwise) {
			while (angle < 0) { angle += 360 }
			
		} else {
			while (angle > 0) { angle -= 360 }
		}
		
		// Update our value by as much as the last motion defined.
		pseudoValueForTouch += Float(angle * angleToValue)
		
		// And make sure we don't count more than one whole circle of overflow.
		if (pseudoValueForTouch > valueMinimum + valueRange * 2) {
			pseudoValueForTouch -= valueRange
		}
		if (pseudoValueForTouch < valueMinimum - valueRange) {
			pseudoValueForTouch += valueRange
		}
		
		return pseudoValueForTouch
	}
	
	private func isClockwise(vector1 vector1: CGPoint, vector2: CGPoint) -> Bool {
		return vector1.y * vector2.x < vector1.x * vector2.y
	}
	
	private func angleAt(point: CGPoint) -> Double {
		// Calculate the relative angle of the user's touch point starting from
		// trackMinAngle.
		var angle = (Double(atan2(point.x - bounds.midX, point.y - bounds.midY)) /
			M_PI * 180.0 + trackMinAngle) + 180
		angle = (90 - angle) % 360
		while (angle < 0) { angle += 360 }
		
		return angle
	}
}
