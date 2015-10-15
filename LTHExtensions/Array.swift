//
//  Array.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

extension Array {
	func each(f: (Element) -> ()) {
		for e in self {
			f(e)
		}
	}
}

func + <T>(left: [T], right: T) -> [T] {
	var l = left
	l << right
	
	return l
}

func << <T>(inout left: [T], right: T) {
	left.append(right)
}

func << <T>(inout left: [T], right: [T]) {
	left += right
}