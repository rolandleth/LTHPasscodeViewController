//
//  OperatorOverloads.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit
import Foundation

@infix func * (left: Character, right: Int) -> String {
    var newString = ""
    right.times {
        newString += String(left)
    }
    return newString
}

// Thanks to http://airspeedvelocity.net/2014/06/10/implementing-rubys-operator-in-swift/
@assignment func ||= <T>(inout lhs: T?, rhs: @auto_closure () -> T) {
    if !lhs {
        lhs = rhs()
    }
}

@assignment func ||= <T: LogicValue>(inout lhs: T, rhs: @auto_closure () -> T) {
    if !lhs {
        lhs = rhs()
    }
}