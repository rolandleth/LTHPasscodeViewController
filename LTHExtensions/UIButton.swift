//
//  UIButton.swift
//  LTHExtensions
//
//  Created by Roland Leth on 22.6.14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit

extension UIButton {
	var custom: UIButton { return UIButton(type: .Custom) }
	var system: UIButton { return UIButton(type: .System) }
	var detailDisclosure: UIButton { return UIButton(type: .DetailDisclosure) }
	var infoLight: UIButton { return UIButton(type: .InfoLight) }
	var infoDark: UIButton { return UIButton(type: .InfoDark) }
	var contactAdd: UIButton { return UIButton(type: .ContactAdd) }
	
	func alignImageOnTheRightOfTitle() {
		titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageView!.width + 7), bottom: 0, right: imageView!.width + 7)
		imageEdgeInsets = UIEdgeInsets(
			top: 0, left: titleLabel!.width + 7,
			bottom: 0, right: -(titleLabel!.width + 7)
		)
	}
	
	func alignImageOnTheLeftOfTitle() {
		titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -11)
		imageEdgeInsets = UIEdgeInsets(top: 0, left: -7, bottom: 0, right: 0)
	}
}