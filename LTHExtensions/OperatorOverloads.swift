//
//  OperatorOverloads.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit
import Foundation

infix operator  |> { associativity left }
infix operator  ||| {}
infix operator  ||= {}

func * (left: Character, right: Int) -> String {
	var newString = ""
	right.times {
		newString += String(left)
	}
	return newString
}

// Thanks to https://gist.github.com/kristopherjohnson/ed97acf0bbe0013df8af
func |> <T,U>(lhs : T, rhs : T -> U) -> U {
	return rhs(lhs);
}

func |||<T> (left: T?, right: T) -> T  {
	if let l = left { return l }
	return right
}

func |||<T,V> (left: T?, right: V) -> Any  {
	if let l = left { return l }
	return right
}

// Thanks to http://airspeedvelocity.net/2014/06/10/implementing-rubys-operator-in-swift/
func ||= <T>(inout lhs: T?, @autoclosure rhs:  () -> T) {
	if lhs == nil {
		lhs = rhs()
	}
}