//
//  LTHArray.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit
import Foundation

extension Array {
    var first: Element? {
        if isEmpty {
            return nil
        }
            
        return self[0]
    }
    
    var last: Element? {
        if isEmpty {
            return nil
        }
            
        return self[count - 1]
    }
}

@infix func + <T>(left: T[], right: T) -> T[] {
    var l = left
    l << right
    
    return l
}

@assignment func << <T>(inout left: T[], right: T) {
    left += right
}

@assignment func << <T>(inout left: T[], right: T[]) {
    left += right
}