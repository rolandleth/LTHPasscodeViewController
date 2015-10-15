//
//  Image.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
	class func imageWithColor(color: UIColor) -> UIImage {
		let rect = CGRectMake(0, 0, 1, 1)
		UIGraphicsBeginImageContextWithOptions(rect.size, false, 2)
		let context = UIGraphicsGetCurrentContext()
		
		CGContextSetFillColorWithColor(context, color.CGColor)
		CGContextFillRect(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
	
	func tintedImageWithColor(tintColor: UIColor, blendMode: CGBlendMode) -> UIImage {
		let bounds = CGRectMake(0, 0, self.size.width, self.size.height)
		
		UIGraphicsBeginImageContextWithOptions(self.size, false, 2);
		tintColor.setFill()
		UIRectFill(bounds);
		drawInRect(bounds, blendMode: blendMode, alpha: 1.0)
		
		if blendMode.rawValue != CGBlendMode.DestinationIn.rawValue {
			drawInRect(bounds, blendMode:CGBlendMode.DestinationIn, alpha:1.0)
		}
		
		let tintedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return tintedImage;
	}
}