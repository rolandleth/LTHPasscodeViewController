//
//  LTHUIView(Extension).swift
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
