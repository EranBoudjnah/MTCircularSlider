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

public enum MTCircularSliderError: Error {
	case WindingsSetToPartialSlider
}

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
	case maxWinds(Float)

	/* Thumb */
	case hasThumb(Bool)
	case thumbTint(UIColor)
	case thumbRadius(CGFloat)
	case thumbShadowRadius(CGFloat)
	case thumbShadowDepth(CGFloat)
}

@IBDesignable
open class MTCircularSlider: UIControl {
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
	var trackMinAngle: Double = 0.0 {
		didSet {
			do {
				try noWindingIfNotFullCircle()
			} catch MTCircularSliderError.WindingsSetToPartialSlider {
				print("Error: Cannot set maxWinds to values other than 1 if MTCircularSlider doesn't close a full circle. Try changing trackMinAngle or trackMaxAngle.")
			} catch {
				print("Error: Unknown error")
			}
			setNeedsDisplay()
		}
	}

	@IBInspectable
	var trackMaxAngle: Double = 360.0 {
		didSet {
			do {
				try noWindingIfNotFullCircle()
			} catch MTCircularSliderError.WindingsSetToPartialSlider {
				print("Error: Cannot set maxWinds to values other than 1 if MTCircularSlider doesn't close a full circle. Try changing trackMinAngle or trackMaxAngle.")
			} catch {
				print("Error: Unknown error")
			}
			setNeedsDisplay()
		}
	}

	@IBInspectable
	var hasThumb: Bool = true { didSet { setNeedsDisplay() } }

	@IBInspectable
	var thumbTint: UIColor = UIColor.white

	@IBInspectable
	var thumbRadius: CGFloat = 14 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var thumbShadowRadius: CGFloat = 2 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var thumbShadowDepth: CGFloat = 3 { didSet { setNeedsDisplay() } }

	@IBInspectable
	open var value: Float = 0.5 {
		didSet {
			let cappedVal = cappedValue(value, forWinds: maxWinds)
			if value != cappedVal { value = cappedVal }
			setNeedsDisplay()

			sendActions(for: .valueChanged)
		}
	}

	@IBInspectable
	open var valueMinimum: Float = 0 {
		didSet {
			value = cappedValue(value)
			setNeedsDisplay()
		}
	}
	
	@IBInspectable
	open var valueMaximum: Float = 1 {
		didSet {
			value = cappedValue(value)
			setNeedsDisplay()
		}
	}

	@IBInspectable
	open var maxWinds: Float = 1 {
		didSet {
			do {
				try noWindingIfNotFullCircle()
			} catch MTCircularSliderError.WindingsSetToPartialSlider {
				print("Error: Cannot set maxWinds to values other than 1 if MTCircularSlider doesn't close a full circle. Try changing trackMinAngle or trackMaxAngle.")
			} catch {
				print("Error: Unknown error")
			}
		}
	}

	fileprivate var isLeftToRight: Bool {
		if #available(iOS 9.0, *) {
			return UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == UIUserInterfaceLayoutDirection.leftToRight
		} else {
			// Fallback on earlier versions
			return true
		}
	}
	
	fileprivate var thumbLayer = CAShapeLayer()
	
	fileprivate var viewCenter: CGPoint {
		return convert(center, from: superview)
	}
	
	fileprivate var thumbCenter: CGPoint {
		var thumbCenter = viewCenter
		let angle = rtlAwareAngle(thumbAngle)
		thumbCenter.x += CGFloat(cos(angle)) * controlRadius
		thumbCenter.y += CGFloat(sin(angle)) * controlRadius
		return thumbCenter
	}
	
	fileprivate var controlRadius: CGFloat {
		return min(bounds.width, bounds.height) / 2.0 - controlThickness
	}
	
	fileprivate var controlThickness: CGFloat {
		let thumbRadius = (hasThumb) ? self.thumbRadius : 0
		return max(thumbRadius, trackWidth / 2.0)
	}
	
	fileprivate var innerControlRadius: CGFloat {
		return controlRadius - trackWidth * 0.5
	}
	
	fileprivate var outerControlRadius: CGFloat {
		return controlRadius + trackWidth * 0.5
	}
	
	fileprivate var thumbAngle: CGFloat {
		let normalizedValue = (value - valueMinimum) / (valueMaximum - valueMinimum)
		let degrees = Double(normalizedValue) * (trackMaxAngle - trackMinAngle) +
			trackMinAngle
		// Convert to radians and rotate 180 degrees so that 0 degrees would be on
		// the left.
		let radians = degrees / 180.0 * M_PI + M_PI
		return CGFloat(radians)
	}
	
	fileprivate var lastPositionForTouch = CGPoint.zero
	
	fileprivate var pseudoValueForTouch = Float(0.0)
	
	override
	open var center: CGPoint {
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
	open func prepareForInterfaceBuilder() {
		prepare()
		
		// Due to a bug in XCode, the shadow is misplaced in Interface Builder.
		thumbShadowDepth = -thumbShadowDepth * 2
		thumbShadowRadius *= 2
	}
	
	override
	open func draw(_ rect: CGRect) {
		/**
		Returns a UIBezierPath with the shape of a ring slice.
		
		- parameter arcCenter:   The center of the ring
		- parameter innerRadius: The inner radius of the ring
		- parameter outerRadius: The outer radius of the ring
		- parameter startAngle:  The start angle of the ring slice
		- parameter endAngle:    The end angle of the ring slice
		
		- returns: A UIBezierPath with the shape of a ring slice.
		*/
		func getArcPath(_ arcCenter: CGPoint, innerRadius: CGFloat,
		                  outerRadius: CGFloat, startAngle: CGFloat,
		                  endAngle: CGFloat) -> UIBezierPath {
			let arcPath = UIBezierPath(arcCenter: arcCenter,
			                           radius: outerRadius,
			                           startAngle: startAngle,
			                           endAngle: endAngle,
			                           clockwise: true)
			
			arcPath.addArc(withCenter: viewCenter,
			               radius: innerRadius,
			               startAngle: endAngle,
			               endAngle: startAngle,
			               clockwise: false)
			arcPath.close()
			
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

			let progressPath =
				isLeftToRight ?
					getArcPath(viewCenter,
			                              innerRadius: innerControlRadius,
			                              outerRadius: outerControlRadius,
			                              startAngle: rtlAwareAngle(minAngle),
			                              endAngle: rtlAwareAngle(thumbAngle)) :
					getArcPath(viewCenter,
					           innerRadius: innerControlRadius,
					           outerRadius: outerControlRadius,
					           startAngle: rtlAwareAngle(thumbAngle),
					           endAngle: rtlAwareAngle(minAngle))

			minTrackTint.setFill()
			progressPath.fill()
		}

		func setShadow(_ context: CGContext, depth: CGFloat, radius: CGFloat) {
			context.clip(to: CGRect.infinite)
			context.setShadow(offset: CGSize(width: 0, height: depth), blur: radius)
		}
		
		func drawTrack(_ context: CGContext) {
			let trackPath = circlePath(withCenter: viewCenter,
			                           radius: outerControlRadius)
			maxTrackTint.setFill()
			trackPath.fill()
			
			if trackShadowDepth > 0 {
				setShadow(context, depth: trackShadowDepth, radius: trackShadowRadius)
			}
			
			let trackShadowPath = UIBezierPath(rect: CGRect.infinite)
			
			trackShadowPath.append(
				circlePath(withCenter: viewCenter,
					radius: CGFloat(outerControlRadius + 0.5))
			)
			
			trackShadowPath.close()
			
			trackShadowPath.append(
				circlePath(withCenter: viewCenter,
					radius: CGFloat(innerControlRadius - 0.5))
			)
			
			trackShadowPath.usesEvenOddFillRule = true
			
			UIColor.black.set()
			trackShadowPath.fill()
		}
		
		func drawThumb() {
			let thumbPath = circlePath(withCenter: thumbCenter,
			                           radius: thumbRadius)
			
			let thumbHasShadow = thumbShadowDepth != 0 || thumbShadowRadius != 0
			
			if hasThumb && thumbHasShadow {
				thumbLayer.path = thumbPath.cgPath
				thumbLayer.fillColor = thumbTint.cgColor
				
				thumbLayer.shadowColor = UIColor.black.cgColor
				thumbLayer.shadowPath = thumbPath.cgPath
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
		context!.saveGState()
		
		clipPath()
		
		drawTrack(context!)
		
		context!.restoreGState()
		
		drawProgress()
		
		drawThumb()
	}

	fileprivate func rtlAwareAngle(_ angle: CGFloat) -> CGFloat {
		return isLeftToRight ? angle : CGFloat(M_PI) - angle
	}

	override
	open func beginTracking(_ touch: UITouch,
	                          with event: UIEvent?) -> Bool {
		if hasThumb {
			let location = touch.location(in: self)

			let pseudoValue = calculatePseudoValue(at: location)
			// If the touch is on the thumb, start dragging from the thumb.
			if locationOnThumb(location) {
				lastPositionForTouch = location
				pseudoValueForTouch = value
//				calculatePseudoValue(at: thumbCenter)
				return true
			}

			// Check if the touch is out of our bounds.
			if cappedValue(pseudoValue) != pseudoValue {
					// Not on thumb or track, so abort gesture.
					return false
			}

			if value > valueMaximum {
				// More than one winding, multiple possible values. Abort.
				return false
			}
			value = pseudoValue
			lastPositionForTouch = location
		}
		
		return super.beginTracking(touch, with: event)
	}
	
	override
	open func continueTracking(_ touch: UITouch,
	                             with event: UIEvent?) -> Bool {
		if !hasThumb {
			return super.continueTracking(touch, with: event)
		}
		
		let location = touch.location(in: self)
		
		value = calculatePseudoValue(lastPositionForTouch, to: location)
		
		lastPositionForTouch = location
		
		return true
	}
	
	// Iterate over the provided attributes and set the corresponding values.
	open func configure(_ attributes: [Attributes]) {
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
			case let .maxWinds(value):
				self.maxWinds = value

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
	
	/**
	Returns the current angle of the thumb in radians.
	*/
	open func getThumbAngle() -> CGFloat {
		return thumbAngle
	}
	
	fileprivate func prepare() {
		contentMode = .redraw
		isOpaque = false
		backgroundColor = UIColor.clear

		layer.insertSublayer(thumbLayer, at: 0)
	}

	fileprivate func cappedValue(_ value: Float) -> Float {
		return cappedValue(value, forWinds: 1)
	}

	fileprivate func cappedValue(_ value: Float, forWinds: Float) -> Float {
		return min(max(valueMinimum, value), valueMaximum + (valueMaximum - valueMinimum) * (maxWinds - 1))
	}

	fileprivate func circlePath(withCenter center: CGPoint,
	                                       radius: CGFloat) -> UIBezierPath {
		return UIBezierPath(arcCenter: center,
		                    radius: radius,
		                    startAngle: 0,
		                    endAngle: CGFloat(M_PI * 2.0),
		                    clockwise: true)
	}
	
	// True if the provided location is on the thumb, false otherwise.
	fileprivate func locationOnThumb(_ location: CGPoint) -> Bool {
		let thumbCenter = self.thumbCenter
		return sqrt(pow(location.x - thumbCenter.x, 2) +
			pow(location.y - thumbCenter.y, 2)) <= thumbRadius
	}

	@discardableResult
	fileprivate func calculatePseudoValue(at point: CGPoint) -> Float {
		let angle = angleAt(point)
		let range = valueMaximum - valueMinimum
		let windings = value == valueMinimum ? 1 :
			ceil((value - valueMinimum) / range)

		// Normalize the angle, then convert to value scale.
		let angleRange = trackMaxAngle - trackMinAngle
		let targetValue =
			(Float(angle) / Float(angleRange) + windings - 1) * range + Float(valueMinimum)

		pseudoValueForTouch = targetValue

		return targetValue
	}
	
	fileprivate func calculatePseudoValue(_ from: CGPoint, to: CGPoint) -> Float {
		let angle1 = angleAt(from)
		let angle2 = angleAt(to)
		var angle = angle2 - angle1
		let valueRange = valueMaximum - valueMinimum
		let angleToValue =
			Double(valueRange) / (trackMaxAngle - trackMinAngle)
		let clockwise = isClockwise(
			CGPoint(x: from.x - bounds.midX, y: from.y - bounds.midY),
			vector2: CGPoint(x: to.x - from.x, y: to.y - from.y)
		)

		if (clockwise == isLeftToRight) {
			while (angle < 0) { angle += 360 }
			
		} else {
			while (angle > 0) { angle -= 360 }
		}
		
		// Update our value by as much as the last motion defined.
		pseudoValueForTouch += Float(angle * angleToValue)

		// And make sure we don't count more than winds circles of overflow.
		if (pseudoValueForTouch > valueMinimum + valueRange * (maxWinds + 1)) {
			pseudoValueForTouch -= valueRange
		}
		if (pseudoValueForTouch < valueMinimum - valueRange) {
			pseudoValueForTouch += valueRange
		}
		
		return pseudoValueForTouch
	}
	
	fileprivate func isClockwise(_ vector1: CGPoint, vector2: CGPoint) -> Bool {
		return vector1.y * vector2.x < vector1.x * vector2.y
	}
	
	fileprivate func angleAt(_ point: CGPoint) -> Double {
		// Calculate the relative angle of the user's touch point starting from
		// trackMinAngle.
		var angle = (Double(atan2(point.x - bounds.midX, point.y - bounds.midY)) /
			M_PI * 180.0 + trackMinAngle) + 180
		if (!isLeftToRight) {
			angle = 360 - angle
		}
		angle = (90 - angle).truncatingRemainder(dividingBy: 360)
		while (angle < 0) { angle += 360 }

		return angle
	}
	
	fileprivate func noWindingIfNotFullCircle() throws {
		guard maxWinds == 1 || trackMaxAngle - trackMinAngle == 360 else {
			throw MTCircularSliderError.WindingsSetToPartialSlider
		}
	}
}
