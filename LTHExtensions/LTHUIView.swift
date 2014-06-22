//
//  LTHUIView.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import UIKit

extension UIView {
    var x: Float {
    get {
        return frame.origin.x
    }
    set {
        frame = CGRectMake(newValue, y, width, height)
    }
    }
    
    var y: Float {
    get {
        return frame.origin.y
    }
    set {
        frame = CGRectMake(x, newValue, width, height)
    }
    }
    
    var width: Float {
    get {
        return frame.size.width
    }
    set {
        frame = CGRectMake(x, y, newValue, height)
    }
    }
    
    var height: Float {
    get {
        return frame.size.height
    }
    set {
        frame = CGRectMake(x, y, width, newValue)
    }
    }
    
    subscript(digitIndex: Int) -> AnyObject? {
        var i = 0
        for view: AnyObject in subviews {
            if i == digitIndex {
                return view
            }
            i++
        }
            
        return nil
    }
}

@assignment func << <T: UIView>(inout left: T, right: T) {
    left.addSubview(right)
}
