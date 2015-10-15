//
//  Utils.swift
//  LTHExtensions
//
//  Created by Roland Leth on 4/6/14.
//  Copyright (c) 2014 Roland Leth. All rights reserved.
//

import Foundation
import UIKit

enum LTHViewTag: Int {
	case CartViewCartButton = 9988
}

struct Utils {
	static func rotateViewAccordingToOrientation(view: UIView, animated: Bool) {
		if Utils.iOS8 {
			return
		}
		
		if !animated {
			let t = view.transform
			if Utils.landscapeLeft {
				view.transform = CGAffineTransformRotate(t, CGFloat(-M_PI/2))
			}
			else if Utils.landscapeRight {
				view.transform = CGAffineTransformRotate(t, CGFloat(M_PI/2))
			}
			else if Utils.portraitUpsideDown {
				view.transform = CGAffineTransformRotate(t, CGFloat(M_PI))
			}
			else {
				view.transform = CGAffineTransformRotate(t, 0)
			}
			
			return
		}
		
		UIView.animateWithDuration(0.35, animations: { () -> Void in
			if Utils.landscapeLeft {
				view.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI/2))
			}
			else if Utils.landscapeRight {
				view.transform = CGAffineTransformMakeRotation(CGFloat(M_PI/2))
			}
			else if Utils.portraitUpsideDown {
				view.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
			}
			else {
				view.transform = CGAffineTransformMakeRotation(0)
			}
		})
	}
	
	static var orientation: UIInterfaceOrientation {
		return UIApplication.sharedApplication().statusBarOrientation
	}
	
	static var landscape: Bool {
		return UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeLeft || UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight
	}
	
	static var landscapeLeft: Bool {
		return UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeLeft
	}
	
	static var landscapeRight: Bool {
		return UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight
	}
	
	static var portrait: Bool {
		return UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.Portrait ||
			UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.PortraitUpsideDown
	}
	
	static var portraitUpsideDown: Bool {
		return UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.PortraitUpsideDown
	}
	
	static var statusBarHeight: CGFloat {
		if landscape && !iOS8 {
			return UIApplication.sharedApplication().statusBarFrame.width
		}
		
		return UIApplication.sharedApplication().statusBarFrame.height
	}
	
	static var winHeight: CGFloat {
		if landscape && !iOS8 {
			return UIScreen.mainScreen().bounds.width
		}
		return UIScreen.mainScreen().bounds.height
	}
	
	static var winWidth: CGFloat {
		if landscape && !iOS8 {
			return UIScreen.mainScreen().bounds.height
		}
		return UIScreen.mainScreen().bounds.width
	}
	
	static var iPhone6Plus: Bool {
		return UIScreen.mainScreen().bounds.size.height == 736.0 // @3x = 2208
	}
	
	static var iPhone6: Bool {
		return UIScreen.mainScreen().bounds.size.height == 667.0 // @2x = 1334
	}
	
	static var iPhone5: Bool {
		return UIScreen.mainScreen().bounds.size.height == 568.0 // @2x = 1136
	}
	
	static var iPhone4: Bool {
		return UIScreen.mainScreen().bounds.size.height < 568.0
	}
	
	static var iPad: Bool {
		return UIDevice.currentDevice().userInterfaceIdiom == .Pad
	}
	
	static var iOS8: Bool {
		return UIDevice.currentDevice().systemVersion.floatValue >= 8.0
	}
	
	static var screenCenter: CGPoint {
		return CGPointMake(UIScreen.mainScreen().bounds.width * 0.5, UIScreen.mainScreen().bounds.height * 0.5)
	}
	
	static func dispatch_low(closure: () -> ()) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
			closure()
		}
	}
	
	static func dispatch_default(closure: () -> ()) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			closure()
		}
	}
	
	static func dispatch_high(closure: () -> ()) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
			closure()
		}
	}
	
	static func dispatch_background(closure: () -> ()) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
			closure()
		}
	}
	
	static func dispatch_main(closure: () -> ()) {
		dispatch_async(dispatch_get_main_queue()) {
			closure()
		}
	}
	
	static func delay(delay: Double, closure: () -> ()) {
		dispatch_after(
			dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
			dispatch_get_main_queue(),
			closure
		)
	}
	
	/// Because creating a number formatter eats a lot of resources.
	static var numberFormatter: NSNumberFormatter {
		let formatter: NSNumberFormatter = NSNumberFormatter()
		
		// Reset every time and set the required properties outside
		formatter.locale = NSLocale.currentLocale()
		formatter.maximumFractionDigits = 2
		formatter.minimumFractionDigits = 0
		formatter.alwaysShowsDecimalSeparator = false
		formatter.numberStyle = .NoStyle
		
		return formatter
	}
	
	/// Because creating a date formatter eats a lot of resources.
	static var dateFormatter: NSDateFormatter {
		struct Static {
			static let formatter : NSDateFormatter = NSDateFormatter()
		}
		
		// Reset every time and set the required properties outside
		Static.formatter.locale = NSLocale.currentLocale()
		Static.formatter.dateFormat = nil
		
		return Static.formatter
	}
	
	static func tryToOpenURL(url: NSURL) {
		if UIApplication.sharedApplication().canOpenURL(url) {
			UIApplication.sharedApplication().openURL(url)
		}
	}
	
	// MARK:- View helpers
	static func reloadCollectionViewAnimated(collectionView: UICollectionView, duration: NSTimeInterval = 0.15) {
		transitionWith(collectionView,
			duration: duration,
			closure: { () -> Void in
				collectionView.reloadData()
			}, completion: nil)
	}
	
	static func reloadTableViewAnimated(tableView: UITableView, duration: NSTimeInterval = 0.15) {
		transitionWith(tableView,
			duration: duration,
			closure: { () -> Void in
				tableView.reloadData()
			}, completion: nil)
	}
	
	static func transitionWith(view: UIView, duration: NSTimeInterval, options: UIViewAnimationOptions = .TransitionCrossDissolve, closure: () -> Void) {
		transitionWith(view, duration: duration, options: options, closure: closure, completion: nil)
	}
	
	static func transitionWith(view: UIView, duration: NSTimeInterval, options: UIViewAnimationOptions = .TransitionCrossDissolve, closure: () -> Void, completion: ((Bool) -> Void)? = nil) {
		Utils.dispatch_main {
			UIView.transitionWithView(view,
				duration: duration,
				options: options,
				animations: { () -> Void in
					closure()
				}, completion: completion)
		}
	}
	
	static func centerView(view1: UIView, andView view2: UIView, inWidth width: CGFloat, withPadding padding: CGFloat) {
		view1.center = CGPoint(x: width * 0.5 - view2.width * 0.5 - padding * 0.5, y: view1.center.y)
		view2.x = view1.x + view1.width + padding
	}
	
	static func centerView(view: UIView, inWidth width: CGFloat) {
		view.center = CGPoint(x: width * 0.5, y: view.center.y)
	}
}

//public extension NSString {
//	var MD5: NSString {
//		return (self as String).MD5
//	}
//}

public func printCallingFunction() {
	let syms = NSThread.callStackSymbols()
	
	if !syms.isEmpty {
		print("\(syms[2])")
	}
	// 0 is this function
	// 1 is the function we want to find the caller for
	// 2 is the caller
}

func psl <T>(toPrint: T) {
	print(toPrint, terminator: "")
}

func p <T>(toPrint: T) {
	print(toPrint)
}

func nslog<T>(
	object: T,
	_ function: String = __FUNCTION__,
	_ file: String = __FILE__,
	_ line: UInt = __LINE__) {
		#if DEBUG
			let filename = NSURL(string: file)?.lastPathComponent?.stringByReplacingOccurrencesOfString(".swift", withString: "") ?? ""
			print("-- \(object) - [\(line)] \(filename).\(function)")
		#endif
}

public func logAndAssert(@autoclosure condition: () -> Bool, message: String = "",
	file: StaticString = __FILE__, line: UInt = __LINE__) {
		
		nslog(message)
		assert(condition, message, file: file, line: line)
}

let UserDefaults = NSUserDefaults.standardUserDefaults()