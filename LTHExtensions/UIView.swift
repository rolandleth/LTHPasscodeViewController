//
//  UIView.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit

extension UIView {
	var x: CGFloat {
		get { return frame.origin.x }
		set { frame = CGRect(x: newValue, y: y, width: width, height: height) }
	}
	
	var y: CGFloat {
		get { return frame.origin.y }
		set { frame = CGRect(x: x, y: newValue, width: width, height: height) }
	}
	
	var width: CGFloat {
		get { return frame.size.width }
		set { frame = CGRect(x: x, y: y, width: newValue, height: height) }
	}
	
	var height: CGFloat {
		get { return frame.size.height }
		set { frame = CGRect(x: x, y: y, width: width, height: newValue) }
	}
	
	subscript(digitIndex: Int) -> AnyObject? {
		var i = 0
		for view: AnyObject in subviews {
			if i == digitIndex {
				return view
			}
			i++
		}
		
		return nil
	}
	
	func centerVerticallyIn(view: UIView) {
		center = CGPoint(x: center.x, y: view.height * 0.5)
	}
	
	func centerHorizontallyIn(view: UIView) {
		center = CGPoint(x: view.width * 0.5, y: self.center.y)
	}
	
	func centerVerticallyWith(view: UIView) {
		center = CGPoint(x: center.x, y: view.center.y)
	}
	
	func centerHorizontallyWith(view: UIView) {
		center = CGPoint(x: view.center.x, y: center.y)
	}
	
	func centerIn(view: UIView) {
		center = CGPoint(x: view.width * 0.5, y: view.height * 0.5)
	}
	
	func fitToWidth(width: CGFloat, andHeight height: CGFloat = CGFloat.max) {
		self.width = width
		self.height = self.sizeThatFits(CGSize(width: width, height: height)).height
	}
	
	func fitToCurrentWidth() {
		self.height = self.sizeThatFits(CGSize(width: width, height: CGFloat.max)).height
	}
	
	func fitToHeight(height: CGFloat, andWidth width: CGFloat = CGFloat.max) {
		self.height = height
		self.width = self.sizeThatFits(CGSize(width: width, height: height)).width
	}
	
	func fitToCurrentHeight() {
		self.width = self.sizeThatFits(CGSize(width: CGFloat.max, height: height)).width
	}
}

func << <T: UIView>(inout left: T, right: T) {
	left.addSubview(right)
}
