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

// Just to test that setting the passcode delegate here works.
// You can uncomment below and comment it inside LTHDemoViewController.
@interface LTHAppDelegate () <LTHPasscodeViewControllerDelegate>

@end

@implementation LTHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
    
//    [LTHPasscodeViewController sharedUser].delegate = self;
//    [LTHPasscodeViewController useKeychain:YES];
	if ([LTHPasscodeViewController doesPasscodeExist] &&
        [LTHPasscodeViewController didPasscodeTimerEnd]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                 withLogout:NO
                                                             andLogoutTitle:nil];
	}
	
    return YES;
}

@end
