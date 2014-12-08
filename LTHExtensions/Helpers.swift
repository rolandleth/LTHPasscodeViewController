//
//  Helpers.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation
import UIKit

func psl <T>(toPrint: T) {
	print(toPrint)
}

func p <T>(toPrint: T) {
	println(toPrint)
}

func nslog(
	var message: Any,
	function: String = __FUNCTION__,
	file: String = __FILE__,
	line: UWord = __LINE__) {
		let split = file.split("/")
		let lastPath = split.last! as String
		let secondSplit = lastPath.split(".")
		if let m = message as? Bool {
			if m {
				message = "true"
			}
			else {
				message = "false"
			}
		}
		println("-- \(message) - [\(line)] \(secondSplit.first!).\(function)")
}

func logAndAssert(condition: @autoclosure () -> Bool, message: String = "",
	file: StaticString = __FILE__, line: UWord = __LINE__) {
		
		nslog(message)
		assert(condition, message, file: file, line: line)
}