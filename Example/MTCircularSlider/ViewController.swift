//
//  ViewController.swift
//  UIControls
//
//  Created by Eran Boudjnah on 27/05/2016.
//  Copyright © 2016 Eran Boudjnah. All rights reserved.
//

import UIKit
import MTCircularSlider

class ViewController: UIViewController {
	@IBOutlet weak var progressView: MTCircularSlider!
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var knobWithLabelView: MTCircularSlider!
	@IBOutlet weak var knobView1: MTCircularSlider!
	@IBOutlet weak var knobView2: MTCircularSlider!
	
	fileprivate var timer: Timer?
	fileprivate var direction: Float = 0.01
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		timer = Timer.scheduledTimer(timeInterval: 0.03,
		                             target: self,
		                             selector: #selector(update),
		                             userInfo: nil,
		                             repeats: true)
		
		setValueLabelText()
		
		initCustomKnobs()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		timer!.invalidate()
	}
	
	@IBAction func onSlideChange(_ sender: MTCircularSlider) {
		setValueLabelText()
	}
	
	func update() {
		progressView.value += direction
		knobView1.value = progressView.value
		if progressView.value <= progressView.valueMinimum ||
			progressView.value >= progressView.valueMaximum {
			direction = -direction
		}
	}
	
	fileprivate func setValueLabelText() {
		valueLabel.text = String(Int(knobWithLabelView.value))
	}
	
	fileprivate func initCustomKnobs() {
		knobView1.configure([
			/* Track */
			Attributes.minTrackTint(.lightGray),
			Attributes.maxTrackTint(.darkGray),
			Attributes.trackWidth(4),
			Attributes.trackShadowRadius(0),
			Attributes.trackShadowDepth(0),
			Attributes.trackMinAngle(180),
			Attributes.trackMaxAngle(360),

			/* Thumb */
			Attributes.hasThumb(false)
			])

		knobView1.valueMaximum = progressView.valueMaximum
		
		knobView2.configure([
			/* Track */
			Attributes.minTrackTint(.lightGray),
			Attributes.maxTrackTint(.lightGray),
			Attributes.trackWidth(12),
			Attributes.trackShadowRadius(0),
			Attributes.trackShadowDepth(0),
			Attributes.trackMinAngle(180),
			Attributes.trackMaxAngle(270),

			/* Thumb */
			Attributes.hasThumb(true),
			Attributes.thumbTint(.darkGray),
			Attributes.thumbRadius(8),
			Attributes.thumbShadowRadius(0),
			Attributes.thumbShadowDepth(0)
		])
		
		knobView1.valueMaximum = progressView.valueMaximum
	}
}

