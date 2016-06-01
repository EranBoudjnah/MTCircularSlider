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

	private var timer: NSTimer?
	private var direction: Float = 0.01

	override func viewDidLoad() {
		super.viewDidLoad()

		timer = NSTimer.scheduledTimerWithTimeInterval(0.03,
		                                               target: self,
		                                               selector: #selector(update),
		                                               userInfo: nil,
		                                               repeats: true)

		setValueLabelText()

		initCustomKnobs()
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)

		timer!.invalidate()
	}
	
	@IBAction func onSlideChange(sender: MTCircularSlider) {
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
	
	private func setValueLabelText() {
		valueLabel.text = String(Int(knobWithLabelView.value))
	}

	private func initCustomKnobs() {
		knobView1.configure([
			/* Track */
			.minTrackTint(UIColor.lightGrayColor()),
			.maxTrackTint(UIColor.darkGrayColor()),
			.trackWidth(4),
			.trackShadowRadius(0),
			.trackShadowDepth(0),
			.trackMinAngle(180),
			.trackMaxAngle(360),
			
			/* Thumb */
			.hasThumb(false)
			])

		knobView1.valueMaximum = progressView.valueMaximum

		knobView2.configure([
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
			])
		
		knobView1.valueMaximum = progressView.valueMaximum
	}
}

