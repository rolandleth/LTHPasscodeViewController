//
//  LTHDictionary.swift
//  LTHExtensions
//
//  Created by Roland Leth on 22.6.14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation

@infix func + <K, V>(left: Dictionary<K, V>, right: Dictionary<K, V>) -> Dictionary<K, V> {
    var l = left
    
    for (k, v) in right {
        l[k] = v
    }
    
    return l
}

@assignment func += <K, V>(inout left: Dictionary<K, V>, right: Dictionary<K, V>) {
    left = left + right
}

@assignment func << <K, V>(inout left: Dictionary<K, V>, right: Dictionary<K, V>) {
    left += right
}