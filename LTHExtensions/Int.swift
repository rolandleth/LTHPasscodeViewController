//
//  Int.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation

extension Int {
	var isEven: Bool { return self % 2 == 0 }
	var isOdd: Bool { return !isEven }
	var squared: Int { return self * self }
	var degreesToRadians: Float { return toFloat * 0.0174532925199432958 }
	var toFloat: Float { return Float(self) }
	
	func square() -> Int {
		return self.squared
	}
	
	func times(task: () -> ()) {
		for _ in 0..<self {
			task()
		}
	}
}


