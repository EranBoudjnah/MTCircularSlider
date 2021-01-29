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
	case windingsSetToPartialSlider
}

// MARK: - Attributes for configuring a MTKnobView.
public enum Attributes {
	// MARK: Track style
	case minTrackTint(UIColor)
	case maxTrackTint(UIColor)
	case trackWidth(CGFloat)
	case trackShadowRadius(CGFloat)
	case trackShadowDepth(CGFloat)
	case trackMinAngle(CGFloat)
	case trackMaxAngle(CGFloat)
    case areTrackCapsRound(Bool)
	case maxWinds(CGFloat)

	// MARK: Thumb style
	case hasThumb(Bool)
	case thumbTint(UIColor)
	case thumbRadius(CGFloat)
	case thumbShadowRadius(CGFloat)
	case thumbShadowDepth(CGFloat)
	case thumbBorderWidth(CGFloat)
	case thumbBorderColor(UIColor)

    // MARK: View properties
    case touchPadding(CGFloat)
}

@IBDesignable
open class MTCircularSlider: UIControl {
	@IBInspectable
	var minTrackTint: UIColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)

	@IBInspectable
	var maxTrackTint: UIColor = UIColor(red: 0.71, green: 0.71, blue: 0.71, alpha: 1.0)

	@IBInspectable
	var trackWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var trackShadowRadius: CGFloat = 0.0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var trackShadowDepth: CGFloat = 0.0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var trackMinAngle: CGFloat = 0.0 {
		didSet {
			do {
				try noWindingIfNotFullCircle()
			} catch MTCircularSliderError.windingsSetToPartialSlider {
				print("Error: Cannot set maxWinds to values other than 1 if MTCircularSlider doesn't close a full circle. " +
                    "Try changing trackMinAngle or trackMaxAngle.")
			} catch {
				print("Error: Unknown error")
			}
			setNeedsDisplay()
		}
	}

	@IBInspectable
	var trackMaxAngle: CGFloat = 360.0 {
		didSet {
			do {
				try noWindingIfNotFullCircle()
			} catch MTCircularSliderError.windingsSetToPartialSlider {
				print("Error: Cannot set maxWinds to values other than 1 if MTCircularSlider doesn't close a full circle. " +
                    "Try changing trackMinAngle or trackMaxAngle.")
			} catch {
				print("Error: Unknown error")
			}
			setNeedsDisplay()
		}
	}
    
    @IBInspectable
    var areTrackCapsRound: Bool = false { didSet { setNeedsDisplay() } }
    
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
	var thumbBorderWidth: CGFloat = 0 { didSet { setNeedsDisplay() } }

	@IBInspectable
	var thumbBorderColor: UIColor = UIColor.lightGray

	@IBInspectable
	open var value: CGFloat = 0.5 {
		didSet {
			let cappedVal = cappedValue(value, forWinds: maxWinds)
			if value != cappedVal { value = cappedVal }
			setNeedsDisplay()

			sendActions(for: .valueChanged)
		}
	}

	@IBInspectable
	open var valueMinimum: CGFloat = 0.0 {
		didSet {
			value = cappedValue(value)
			setNeedsDisplay()
		}
	}

	@IBInspectable
	open var valueMaximum: CGFloat = 1.0 {
		didSet {
			value = cappedValue(value)
			setNeedsDisplay()
		}
	}

	@IBInspectable
	open var maxWinds: CGFloat = 1.0 {
		didSet {
			do {
				try noWindingIfNotFullCircle()
			} catch MTCircularSliderError.windingsSetToPartialSlider {
				print("Error: Cannot set maxWinds to values other than 1 if MTCircularSlider doesn't close a full circle. " +
                    "Try changing trackMinAngle or trackMaxAngle.")
			} catch {
				print("Error: Unknown error")
			}
		}
	}

    @IBInspectable
    open var touchPadding: CGFloat = 0.0
    
	fileprivate var isLeftToRight: Bool {
		if #available(iOS 9.0, *) {
			return UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) ==
                UIUserInterfaceLayoutDirection.leftToRight
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
		let angle = rtlAwareAngleRadians(thumbAngle)
		thumbCenter.x += CGFloat(cos(angle)) * controlRadius
		thumbCenter.y += CGFloat(sin(angle)) * controlRadius
		return thumbCenter
	}

	fileprivate var controlRadius: CGFloat {
		return min(bounds.width, bounds.height) / 2.0 - controlThickness
	}

	fileprivate var controlThickness: CGFloat {
		let thumbRadius = (hasThumb) ? self.thumbRadius : 0.0
		return max(thumbRadius, trackWidth / 2.0)
	}

	fileprivate var innerControlRadius: CGFloat {
		return controlRadius - trackWidth * 0.5
	}

	fileprivate var outerControlRadius: CGFloat {
		return controlRadius + trackWidth * 0.5
	}

	fileprivate var thumbAngle: CGFloat {
		let normalizedValue = (value - valueMinimum) / valueRange()
		let degrees = normalizedValue * (trackMaxAngle - trackMinAngle) + trackMinAngle
		// Rotate 180 degrees so that 0 degrees would be on the left and
		// convert to radians.
		let radians = degreesToRadians(degrees + 180.0)
		return CGFloat(radians)
	}

	fileprivate var lastPositionForTouch = CGPoint.zero

	fileprivate var pseudoValueForTouch: CGFloat = 0.0

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
		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()

		clipDrawingPathToTrack()

		drawTrack(context!)

		context?.restoreGState()

		drawProgressOnTrack()

		drawThumb()
	}

    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if (!isUserInteractionEnabled || isHidden) {
            return nil;
        }
        let touchRect = bounds.insetBy(dx: -touchPadding, dy: -touchPadding)
        if (touchRect.contains(point)) {
            return self;
        }
        return nil;
    }

	fileprivate func rtlAwareAngleRadians(_ radians: CGFloat) -> CGFloat {
		return isLeftToRight ? radians : CGFloat(Double.pi) - radians
	}

	// swiftlint:disable cyclomatic_complexity
	open func applyAttributes(_ attributes: [Attributes]) {
		for attribute in attributes {
			switch attribute {
			// MARK: Track style
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
            case let .areTrackCapsRound(value):
                self.areTrackCapsRound = value
			case let .maxWinds(value):
				self.maxWinds = value

			// MARK: Thumb style
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
			case let .thumbBorderWidth(value):
				self.thumbBorderWidth = value
			case let .thumbBorderColor(value):
				self.thumbBorderColor = value

            // MARK: View properties
            case let .touchPadding(value):
                self.touchPadding = value
            }
		}

		setNeedsDisplay()
	}
	// swiftlint:enable cyclomatic_complexity

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

	fileprivate func cappedValue(_ value: CGFloat) -> CGFloat {
		return cappedValue(value, forWinds: 1.0)
	}

	fileprivate func cappedValue(_ value: CGFloat, forWinds: CGFloat) -> CGFloat {
		return min(max(valueMinimum, value), valueMaximum + valueRange() * (maxWinds - 1.0))
	}

	// True if the provided location is on the thumb, false otherwise.
	fileprivate func locationOnThumb(_ location: CGPoint) -> Bool {
		let thumbCenter = self.thumbCenter
		return sqrt(pow(location.x - thumbCenter.x, 2) +
			pow(location.y - thumbCenter.y, 2)) <= thumbRadius
	}

	fileprivate func isClockwise(_ vector1: CGPoint, vector2: CGPoint) -> Bool {
		return vector1.y * vector2.x < vector1.x * vector2.y
	}

	fileprivate func noWindingIfNotFullCircle() throws {
		guard maxWinds == 1 || trackMaxAngle - trackMinAngle == 360 else {
			throw MTCircularSliderError.windingsSetToPartialSlider
		}
	}

	fileprivate func valueRange() -> CGFloat {
		return valueMaximum - valueMinimum
	}
}

// MARK: - Trigonometry converters
fileprivate extension MTCircularSlider {
    func radiansToDegrees(_ angle: CGFloat) -> CGFloat {
        return angle / CGFloat(Double.pi) * 180.0
    }

    func degreesToRadians(_ angle: CGFloat) -> CGFloat {
        return angle / 180.0 * CGFloat(Double.pi)
    }
}

// MARK: - Touch behaviour
extension MTCircularSlider {
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

        value = calculatePseudoValue(fromPoint: lastPositionForTouch, toPoint: location)

        lastPositionForTouch = location

        return true
    }

    @discardableResult
    fileprivate func calculatePseudoValue(at point: CGPoint) -> CGFloat {
        let angle = angleAt(point)
        let range = valueRange()
        let windings = value == valueMinimum ? 1 :
            ceil((value - valueMinimum) / range)

        // Normalize the angle, then convert to value scale.
        let angleRange = trackMaxAngle - trackMinAngle
        let targetValue =
            (angle / angleRange + windings - 1.0) * range + valueMinimum

        pseudoValueForTouch = targetValue

        return targetValue
    }

    fileprivate func calculatePseudoValue(fromPoint: CGPoint, toPoint: CGPoint) -> CGFloat {
        let angle1 = angleAt(fromPoint)
        let angle2 = angleAt(toPoint)
        var angle = angle2 - angle1
        let range = valueRange()
        let angleToValue = range / (trackMaxAngle - trackMinAngle)
        let clockwise = isClockwise(
            CGPoint(x: fromPoint.x - bounds.midX, y: fromPoint.y - bounds.midY),
            vector2: CGPoint(x: toPoint.x - fromPoint.x, y: toPoint.y - fromPoint.y)
        )

        if clockwise == isLeftToRight {
            while angle < 0 { angle += 360 }

        } else {
            while angle > 0 { angle -= 360 }
        }

        // Update our value by as much as the last motion defined.
        pseudoValueForTouch += angle * angleToValue

        // And make sure we don't count more than winds circles of overflow.
        if pseudoValueForTouch > valueMinimum + range * (maxWinds + 1) {
            pseudoValueForTouch -= range
        }
        if pseudoValueForTouch < valueMinimum - range {
            pseudoValueForTouch += range
        }

        return pseudoValueForTouch
    }

    fileprivate func angleAt(_ point: CGPoint) -> CGFloat {
        // Calculate the relative angle of the user's touch point starting from
        // trackMinAngle.
        var angle = (radiansToDegrees(atan2(point.x - bounds.midX, point.y - bounds.midY)) + trackMinAngle) + 180.0
        if !isLeftToRight {
            angle = 360.0 - angle
        }
        angle = (90.0 - angle).truncatingRemainder(dividingBy: 360.0)
        while angle < 0.0 { angle += 360.0 }

        return angle
    }
}

// MARK: - MTCircularSlider Drawing
fileprivate extension MTCircularSlider {
    func clipDrawingPathToTrack() {
        let minAngle = degreesToRadians(trackMinAngle + 180.0)
        let maxAngle = degreesToRadians(trackMaxAngle + 180.0)
        let clipPath = getRingSliceArcPath(ringCenter: viewCenter,
                                           innerRadius: innerControlRadius, outerRadius: outerControlRadius,
                                           startAngle: minAngle, endAngle: maxAngle,
                                           isRounded: self.areTrackCapsRound)

        clipPath.addClip()
    }

    func drawProgressOnTrack() {
        let minAngle = degreesToRadians(trackMinAngle + 180.0)
        let isRounded = self.value != 0 && self.areTrackCapsRound

        let progressPath =
            isLeftToRight ?
                getRingSliceArcPath(ringCenter: viewCenter,
                                    innerRadius: innerControlRadius,
                                    outerRadius: outerControlRadius,
                                    startAngle: rtlAwareAngleRadians(minAngle),
                                    endAngle: rtlAwareAngleRadians(thumbAngle),
                                    isRounded: isRounded) :
                getRingSliceArcPath(ringCenter: viewCenter,
                                    innerRadius: innerControlRadius,
                                    outerRadius: outerControlRadius,
                                    startAngle: rtlAwareAngleRadians(thumbAngle),
                                    endAngle: rtlAwareAngleRadians(minAngle),
                                    isRounded: isRounded)

        minTrackTint.setFill()
        progressPath.fill()
    }

    func drawTrack(_ context: CGContext) {
        let trackPath = getCirclePath(withCenter: viewCenter,
                                   radius: outerControlRadius)
        maxTrackTint.setFill()
        trackPath.fill()

        if trackShadowDepth > 0 {
            setShadow(context, depth: trackShadowDepth, radius: trackShadowRadius)
        }

        let trackShadowPath = UIBezierPath(rect: CGRect.infinite)

        trackShadowPath.append(
            getCirclePath(withCenter: viewCenter,
                       radius: CGFloat(outerControlRadius + 0.5))
        )

        trackShadowPath.close()

        trackShadowPath.append(
            getCirclePath(withCenter: viewCenter,
                       radius: CGFloat(innerControlRadius - 0.5))
        )

        trackShadowPath.usesEvenOddFillRule = true

        UIColor.black.set()
        trackShadowPath.fill()
    }

    func drawThumb() {
        let thumbPath = getCirclePath(withCenter: thumbCenter,
                                      radius: thumbRadius)

        if hasThumb && thumbHasShadow() {
            setThumbLayerPathAndColor(thumbPath)
            setupThumbLayerShadow(thumbPath)

        } else {
            resetThumbPaths()

            if hasThumb {
                thumbTint.setFill()
                thumbPath.fill()
            }
        }

        setThumbStroke()
    }

    func getCirclePath(withCenter center: CGPoint,
                       radius: CGFloat) -> UIBezierPath {
        return UIBezierPath(arcCenter: center,
                            radius: radius,
                            startAngle: 0,
                            endAngle: CGFloat(Double.pi * 2.0),
                            clockwise: true)
    }

    private func getRingSliceArcPath(ringCenter: CGPoint,
                                     innerRadius: CGFloat, outerRadius: CGFloat,
                                     startAngle: CGFloat, endAngle: CGFloat,
                                     isRounded: Bool) -> UIBezierPath {
        let arcPath = UIBezierPath(arcCenter: ringCenter,
                                   radius: outerRadius,
                                   startAngle: startAngle,
                                   endAngle: endAngle,
                                   clockwise: true)
        let ringWidthRadius = (outerRadius - innerRadius) / 2
        
        let ringEdgeCenterPoint = {
            self.edgeCenterPointFrom(
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                angle: $0,
                ringCenter: ringCenter
            )
        }
        
        let addRoundEdge = {
            arcPath.addArc(withCenter: $0, radius: ringWidthRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        }
        
        if isRounded {
            let endCenter = ringEdgeCenterPoint(endAngle)
            addRoundEdge(endCenter)
        }
        
        arcPath.addArc(withCenter: viewCenter,
                       radius: innerRadius,
                       startAngle: endAngle,
                       endAngle: startAngle,
                       clockwise: false)
        
        if isRounded {
            let startCenter = ringEdgeCenterPoint(startAngle)
            addRoundEdge(startCenter)
        }
        
        arcPath.close()

        return arcPath
    }
    
    private func edgeCenterPointFrom(innerRadius: CGFloat, outerRadius: CGFloat,
                                     angle: CGFloat, ringCenter: CGPoint) -> CGPoint {
        let outStartCenter = pointOnCircle(
            radius: outerRadius,
            angle: angle,
            center: ringCenter
        )
        
        let inStartCenter = pointOnCircle(
            radius: innerRadius,
            angle: angle,
            center: ringCenter
        )
        
        return CGPoint(
            x: (outStartCenter.x + inStartCenter.x) / 2,
            y: (outStartCenter.y + inStartCenter.y) / 2
        )
    }
    
    private func pointOnCircle(radius: CGFloat, angle: CGFloat, center: CGPoint) -> CGPoint {
        let calculate: ((CGFloat) -> CGFloat) -> CGFloat = { (radius) * $0(angle) }
        let point = CGPoint(x: calculate(cos), y: calculate(sin))
        
        return CGPoint(x: center.x + point.x, y: center.y + point.y)
    }
    private func setShadow(_ context: CGContext, depth: CGFloat, radius: CGFloat) {
        context.clip(to: CGRect.infinite)
        context.setShadow(offset: CGSize(width: 0, height: depth), blur: radius)
    }

    private func thumbHasShadow() -> Bool {
        return thumbShadowDepth != 0 || thumbShadowRadius != 0
    }

    private func setThumbLayerPathAndColor(_ thumbPath: UIBezierPath) {
        thumbLayer.path = thumbPath.cgPath
        thumbLayer.fillColor = thumbTint.cgColor
    }

    private func setupThumbLayerShadow(_ thumbPath: UIBezierPath) {
        thumbLayer.shadowColor = UIColor.black.cgColor
        thumbLayer.shadowPath = thumbPath.cgPath
        thumbLayer.shadowOffset = CGSize(width: 0, height: thumbShadowDepth)
        thumbLayer.shadowOpacity = 0.25
        thumbLayer.shadowRadius = thumbShadowRadius
    }

    private func resetThumbPaths() {
        thumbLayer.path = nil
        thumbLayer.shadowPath = nil
    }

    private func setThumbStroke() {
        thumbLayer.strokeColor = thumbBorderColor.cgColor
        thumbLayer.lineWidth = thumbBorderWidth
    }
    // swiftlint:disable file_length
}
