//
//  ViewController.swift
//  UIControls
//
//  Created by Eran Boudjnah on 27/05/2016.
//  Copyright © 2016 Mitteloupe. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func onSlideChange(sender: KnobView) {
		print("Value: \(sender.value)")
	}
}

