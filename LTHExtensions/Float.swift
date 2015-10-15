//
//  Float.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation

extension Float {
	var degreesToRadians: Float { return self * 0.0174532925199432958 }
}

extension Double {
	var degreesToRadians: Double { return Double(Float(self).degreesToRadians) }
}