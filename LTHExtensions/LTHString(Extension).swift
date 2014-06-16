//
//  LTHString.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation

extension String {
    var length: Int {
        var i = 0
        for char in self {
            i++
        }
        return i
    }
    
    var isFloat: Bool {
    return NSNumberFormatter().numberFromString(self) != nil && !isEmpty
    }
    
    var isInt: Bool {
    let digits = NSCharacterSet.decimalDigitCharacterSet()
    return digits.isSupersetOfSet(NSCharacterSet(charactersInString: self)) && !isEmpty
    }
    
    func containsString(string: String) -> Bool? {
        return bridgeToObjectiveC().containsString(string)
    }
    
    static func documentPath(pathComponent: String) -> String? {
        if let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0].stringByAppendingPathComponent(pathComponent) {
            return path
        }
        else {
            return nil
        }
    }
    
    subscript(digitIndex: Int) -> Character? {
        var i = 0
        for char in self {
            if i == digitIndex {
                return char
            }
            i++
        }
        return nil
    }
}
