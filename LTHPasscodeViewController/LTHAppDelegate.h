//
//  LTHAppDelegate.h
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LTHPasscodeViewController;
@interface LTHAppDelegate : UIResponder <UIApplicationDelegate> {
	LTHPasscodeViewController *_passcodeController;
}

@property (strong, nonatomic) UIWindow *window;

@end
