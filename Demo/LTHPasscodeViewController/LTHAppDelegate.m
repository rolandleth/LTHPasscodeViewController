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
//	UITabBarController *navController = [[UITabBarController alloc] init];
//	[navController addChildViewController: demoController];
	self.window.rootViewController = navController;
	[self.window makeKeyAndVisible];
	
	if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		// Init the singleton
		[LTHPasscodeViewController sharedUser];
		if ([LTHPasscodeViewController didPasscodeTimerEnd])
			[[LTHPasscodeViewController sharedUser] showLockscreenWithAnimation: YES];
	}
	
    return YES;
}

@end
