# MTCircularSlider

[![CI Status](http://img.shields.io/travis/EranBoudjnah/MTCircularSlider.svg?style=flat)](https://travis-ci.org/EranBoudjnah/MTCircularSlider)
[![Version](https://img.shields.io/cocoapods/v/MTCircularSlider.svg?style=flat)](http://cocoapods.org/pods/MTCircularSlider)
[![License](https://img.shields.io/cocoapods/l/MTCircularSlider.svg?style=flat)](http://cocoapods.org/pods/MTCircularSlider)
[![Platform](https://img.shields.io/cocoapods/p/MTCircularSlider.svg?style=flat)](http://cocoapods.org/pods/MTCircularSlider)

## Screenshot

<img src="/../screenshots/screenshots/Simulator%20Screen%20Shot%202%20Jun%202016,%2013.35.42.png?raw=true" width="360" height="640" title="Screenshot from Simulator" alt="Screenshot from Simulator" />

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 8.0+

## Installation

### CocoaPods (iOS 8.0+)

MTCircularSlider is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MTCircularSlider"
```

### Manual Installation

The class file required for MTCircularSlider can be found in the following path:

```
MTCircularSlider/Classes/MTCircularSlider.swift
```

## Usage

To run the example project, clone the repo and run pod install from the Example directory first.

MTCircularSlider implements IBDesignable and IBInspectable, and so can be configure directly from Interface Builder.


### Usage in Code - Simple

To add a default circular slider, add the following code to your controller:

```
self.slider = MTCircularSlider(frame: self.sliderArea.bounds, options: nil)
self.slider?.addTarget(self, action: Selector("valueChange:"), forControlEvents: .ValueChanged)
self.sliderArea.addSubview(self.slider)
```

### Usage in Code - Advanced

To add a custom circular slider, add the following code to your controller:

```swift
let attributes = [
/* Track */
.minTrackTint(UIColor.lightGrayColor()),
.maxTrackTint(UIColor.lightGrayColor()),
.trackWidth(12),
.trackShadowRadius(0),
.trackShadowDepth(0),
.trackMinAngle(180),
.trackMaxAngle(270),

/* Thumb */
.hasThumb(true),
.thumbTint(UIColor.darkGrayColor()),
.thumbRadius(8),
.thumbShadowRadius(0),
.thumbShadowDepth(0)
]

self.slider = MTCircularSlider(frame: self.sliderArea.bounds, options: nil)
self.slider.configure(attributes)
self.slider?.addTarget(self, action: Selector("valueChange:"), forControlEvents: .ValueChanged)
self.sliderArea.addSubview(self.slider)
```

## Attributes

###### ``minTrackTint(UIColor)``

Sets the color of the track up to the thumb.

###### ``maxTrackTint(UIColor)``

Sets the color of the track from the thumb to the end of the track.

###### ``trackWidth(CGFloat)``

Sets the width of the track in points.

###### ``trackShadowRadius(CGFloat)``

Sets the radius for the inner shadow on the track.

###### ``trackShadowDepth(CGFloat)``

Sets the distance of the inner shadow on the track from the track edge.

###### ``trackMinAngle(Double)``

Sets the minimum angle of the track in degrees.

###### ``trackMaxAngle(Double)``

Sets the maximum angle of the track in degrees.

###### ``hasThumb(Bool)``

Toggles the control between progress and slider modes. Setting hasThumb to true
set the control to slider mode.

###### ``thumbTint(UIColor)``

Sets the color of the thumb.

###### ``thumbRadius(CGFloat)``

Sets the radius of the thumb in points.

###### ``thumbShadowRadius(CGFloat)``

Sets the radius of the shadow the thumb drops.

###### ``thumbShadowDepth(CGFloat)``

Sets the distance of the shadow the thumb from the thumb.

## Author

Eran Boudjnah, eranbou@gmail.com

## License

MTCircularSlider is available under the MIT license. See the LICENSE file for more info.
