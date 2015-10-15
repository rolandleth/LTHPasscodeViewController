//
//  Dictionary.swift
//  LTHExtensions
//
//  Created by Roland Leth on 22.6.14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//


extension Dictionary {
	func each(f: (Key, Value) -> ()) {
		for (k, v) in self {
			f(k, v)
		}
	}
}

func + <K, V>(left: [K:V], right: [K:V]) -> [K:V] {
	var l = left
	
	for (k, v) in right {
		l[k] = v
	}
	
	return l
}

func += <K, V>(inout left: [K:V], right: [K:V]) {
	left = left + right
}

func << <K, V>(inout left: [K:V], right: [K:V]) {
	left += right
}