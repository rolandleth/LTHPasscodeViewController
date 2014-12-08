//
//  String.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation
import UIKit

extension String {
	var length: Int {
		var i = 0
		for char in self {
			i++
		}
		return i
	}
	
	var boolValue: Bool {
		return NSString(string: self).boolValue
	}
	
	var intValue: Int {
		return NSString(string: self).integerValue
	}
	
	var floatValue: Float {
		return NSString(string: self).floatValue
	}
	
	var doubleValue: Double {
		return NSString(string: self).doubleValue
	}
	
	var isFloat: Bool {
		return NSNumberFormatter().numberFromString(self) != nil && !isEmpty
	}
	
	var isInt: Bool {
		let digits = NSCharacterSet.decimalDigitCharacterSet()
		return digits.isSupersetOfSet(NSCharacterSet(charactersInString: self)) && !isEmpty
	}
	
	func containsString(string: String) -> Bool {
		return self.rangeOfString(string) != nil
	}
	
	static func documentPath(pathComponent: String) -> String? {
		return NSSearchPathForDirectoriesInDomains(
			.DocumentDirectory,
			.UserDomainMask,
			true)[0].stringByAppendingPathComponent(pathComponent)
	}
	
	func uiimage() -> UIImage? {
		return UIImage(named: self)
	}
	
	func uifont(fontSize: CGFloat) -> UIFont? {
		return UIFont(name: self, size: fontSize)
	}
	
	func uifont() -> UIFont? {
		return uifont(UIFont.systemFontSize())
	}
	
	func split(delimiter: String?) -> [AnyObject] {
		if let separator = delimiter {
			return self.componentsSeparatedByString(separator)
		}
		else {
			return self.componentsSeparatedByString("")
		}
	}
	
	subscript(pos: Int) -> String {
		return self[pos...pos]
	}
	
	subscript(range: Range<Int>) -> String {
		let start = advance(startIndex, range.startIndex)
		let end = advance(startIndex, range.endIndex)
		
		return substringWithRange(Range(start: start, end: end))
	}
}

func * (left: String, right: Int) -> String {
	var newString = ""
	right.times {
		newString += left
	}
	
	return newString
}

func << (inout left: String, right: String) {
	left += right
}

func << (inout left: String, right: Character) {
	left += String(right)
}
