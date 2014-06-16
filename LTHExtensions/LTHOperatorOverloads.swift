//
//  OperatorOverloads.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit
import Foundation

@infix func +<K, V> (left: Dictionary<K, V>, right: Dictionary<K, V>) -> Dictionary<K, V> {
    var l = left
    
    for (k, v) in right {
        l[k] = v
    }
    
    return l
}

@infix func +<T> (left: T[], right: T) -> T[] {
    var l = left
    l << right
    
    return l
}

@infix func * (left: Character, right: Int) -> String {
    var newString = ""
    right.times {
        newString += String(left)
    }
    return newString
}

@infix func * (left: String, right: Int) -> String {
    var newString = ""
    right.times {
        newString += String(left)
    }
    return newString
}

@assignment func +=<K, V> (inout left: Dictionary<K, V>, right: Dictionary<K, V>) {
    left = left + right
}

@assignment func <<<K, V> (inout left: Dictionary<K, V>, right: Dictionary<K, V>) {
    left += right
}

@assignment func <<<T> (inout left: T[], right: T) {
    left.append(right)
}

@assignment func <<<T: UIView> (inout left: T, right: T) {
    left.addSubview(right)
}