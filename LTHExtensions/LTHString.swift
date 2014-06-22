//
//  LTHString.swift
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
    
    var toBool: Bool {
    return self.bridgeToObjectiveC().boolValue
    }
    
    var toInt: Int {
    return self.bridgeToObjectiveC().integerValue
    }
    
    var toFloat: Float {
    return self.bridgeToObjectiveC().floatValue
    }
    
    var toDouble: Double {
    return self.bridgeToObjectiveC().doubleValue
    }
    
    var isFloat: Bool {
    return NSNumberFormatter().numberFromString(self) != nil && !isEmpty
    }
    
    var isInt: Bool {
    let digits = NSCharacterSet.decimalDigitCharacterSet()
    return digits.isSupersetOfSet(NSCharacterSet(charactersInString: self)) && !isEmpty
    }
    
    func containsString(string: String) -> Bool {
        return bridgeToObjectiveC().containsString(string)
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
    
    func uifont(fontSize: Float) -> UIFont? {
        return UIFont(name: self, size: fontSize)
    }
    
    func uifont() -> UIFont? {
        return uifont(UIFont.systemFontSize())
    }
    
    subscript(digitIndex: Int) -> Character? {
        if (digitIndex > length || digitIndex < 0) {
            return nil
        }
            
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

@infix func * (left: String, right: Int) -> String {
    var newString = ""
    right.times {
        newString += String(left)
    }
    
    return newString
}

@assignment func << (inout left: String, right: String) {
    left += right
}

@assignment func << (inout left: String, right: Character) {
    left += right
}
