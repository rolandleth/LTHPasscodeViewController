//
//  LTHDemoViewController.m
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHDemoViewController.h"
#import "LTHPasscodeViewController.h"
#import "LTHAppDelegate.h"

@implementation LTHDemoViewController


- (void)refreshUI {
	if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		_enablePasscode.enabled = NO;
		_changePasscode.enabled = YES;
		_turnOffPasscode.enabled = YES;
		_testPasscode.enabled = YES;
		
		_changePasscode.backgroundColor = [UIColor colorWithRed:0.50f green:0.30f blue:0.87f alpha:1.00f];
		_testPasscode.backgroundColor = [UIColor colorWithRed:0.000f green:0.645f blue:0.608f alpha:1.000f];
		_enablePasscode.backgroundColor = [UIColor colorWithWhite: 0.8f alpha: 1.0f];
		_turnOffPasscode.backgroundColor = [UIColor colorWithRed:0.8f green:0.1f blue:0.2f alpha:1.000f];
	}
	else {
		_enablePasscode.enabled = YES;
		_changePasscode.enabled = NO;
		_turnOffPasscode.enabled = NO;
		_testPasscode.enabled = NO;
		
		_changePasscode.backgroundColor = [UIColor colorWithWhite: 0.8f alpha: 1.0f];
		_enablePasscode.backgroundColor = [UIColor colorWithRed:0.000f green:0.645f blue:0.608f alpha:1.000f];
		_testPasscode.backgroundColor = [UIColor colorWithWhite: 0.8f alpha: 1.0f];
		_turnOffPasscode.backgroundColor = [UIColor colorWithWhite: 0.8f alpha: 1.0f];
	}
}


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Demo";
	self.view.backgroundColor = [UIColor whiteColor];
	_changePasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	_enablePasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	_testPasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	_turnOffPasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	
	_enablePasscode.frame = CGRectMake(100, 100, 100, 50);
	_testPasscode.frame = CGRectMake(100, 200, 100, 50);
	_changePasscode.frame = CGRectMake(100, 300, 100, 50);
	_turnOffPasscode.frame = CGRectMake(100, 400, 100, 50);

	
	[_turnOffPasscode setTitle: @"Turn Off" forState: UIControlStateNormal];
	[_changePasscode setTitle: @"Change" forState: UIControlStateNormal];
	[_testPasscode setTitle: @"Test" forState: UIControlStateNormal];
	[_enablePasscode setTitle: @"Enable" forState: UIControlStateNormal];
	
	[self refreshUI];
	
	[_changePasscode addTarget: self action: @selector(_changePasscode) forControlEvents: UIControlEventTouchUpInside];
	[_enablePasscode addTarget: self action: @selector(_enablePasscode) forControlEvents: UIControlEventTouchUpInside];
	[_testPasscode addTarget: self action: @selector(_testPasscode) forControlEvents: UIControlEventTouchUpInside];
	[_turnOffPasscode addTarget: self action: @selector(_turnOffPasscode) forControlEvents: UIControlEventTouchUpInside];
	
	[self.view addSubview: _changePasscode];
	[self.view addSubview: _turnOffPasscode];
	[self.view addSubview: _testPasscode];
	[self.view addSubview: _enablePasscode];
}


- (void)_turnOffPasscode {
	[self showLockViewForTurningPasscodeOff];
}


- (void)_changePasscode {
	[self showLockViewForChangingPasscode];
}


- (void)_enablePasscode {
	[self showLockViewForEnablingPasscode];
}


- (void)_testPasscode {
	[self showLockViewForTestingPasscode];
}


- (void)showLockViewForEnablingPasscode {
	LTHPasscodeViewController *passcodeViewController = [[LTHPasscodeViewController alloc] init];
	passcodeViewController.delegate = self;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: passcodeViewController];
	[self presentViewController: navController animated: YES completion: nil];
}


- (void)showLockViewForTestingPasscode {
	LTHPasscodeViewController *passcodeViewController = [[LTHPasscodeViewController alloc] initForBeingDisplayedAsLockscreen];
	[((LTHAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController.view addSubview: passcodeViewController.view];
	[((LTHAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController addChildViewController: passcodeViewController];
}


- (void)showLockViewForChangingPasscode {
	LTHPasscodeViewController *passcodeViewController = [[LTHPasscodeViewController alloc] initForChangingPasscode];
	passcodeViewController.delegate = self;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: passcodeViewController];
	[self presentViewController: navController animated: YES completion: nil];
}


- (void)showLockViewForTurningPasscodeOff {
	LTHPasscodeViewController *passcodeViewController = [[LTHPasscodeViewController alloc] initForTurningPasscodeOff];
	passcodeViewController.delegate = self;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: passcodeViewController];
	[self presentViewController: navController animated: YES completion: nil];
}


@end
