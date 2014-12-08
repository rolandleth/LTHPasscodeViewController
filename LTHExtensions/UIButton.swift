//
//  UIButton.swift
//  LTHExtensions
//
//  Created by Roland Leth on 22.6.14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
	var custom: UIButton {
		return UIButton.buttonWithType(.Custom) as UIButton
	}
	
	var system: UIButton {
		return UIButton.buttonWithType(.System) as UIButton
	}
	
	var detailDisclosure: UIButton {
		return UIButton.buttonWithType(.DetailDisclosure) as UIButton
	}
	
	var infoLight: UIButton {
		return UIButton.buttonWithType(.InfoLight) as UIButton
	}
	
	var infoDark: UIButton {
		return UIButton.buttonWithType(.InfoDark) as UIButton
	}
	
	var contactAdd: UIButton {
		return UIButton.buttonWithType(.ContactAdd) as UIButton
	}
}