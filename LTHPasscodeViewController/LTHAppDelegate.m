//
//  LTHAppDelegate.m
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHAppDelegate.h"
#import "LTHDemoViewController.h"
#import "LTHPasscodeViewController.h"

@implementation LTHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor blackColor];
	
	LTHDemoViewController *demoController = [[LTHDemoViewController alloc] init];
	demoController.title = nil;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: demoController];
	self.window.rootViewController = navController;
	[self.window makeKeyAndVisible];
	
	if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		[self showLockView];
	}
	
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		[self showLockView];
	}
}


- (void)showLockView {
	// For the case when the user exits the app while the passcode view is on screen
	if (_passcodeController.isCurrentlyOnScreen) return;
	_passcodeController = [[LTHPasscodeViewController alloc] initForBeingDisplayedAsLockscreen];
	[self.window.rootViewController.view addSubview: _passcodeController.view];
	[self.window.rootViewController addChildViewController: _passcodeController];
}

@end
