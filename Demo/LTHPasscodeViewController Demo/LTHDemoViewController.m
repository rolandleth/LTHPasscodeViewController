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
#import <LocalAuthentication/LAContext.h>


@interface LTHDemoViewController () <LTHPasscodeViewControllerDelegate>
@property (nonatomic, strong) UIButton *changePasscode;
@property (nonatomic, strong) UIButton *enablePasscode;
@property (nonatomic, strong) UIButton *testPasscode;
@property (nonatomic, strong) UIButton *turnOffPasscode;
@property (nonatomic, strong) UILabel  *typeLabel;
@property (nonatomic, strong) UISwitch *typeSwitch;
@property (nonatomic, strong) UILabel  *touchIDLabel;
@property (nonatomic, strong) UISwitch *touchIDSwitch;
@end


@implementation LTHDemoViewController


- (void)_refreshUI {
	if ([LTHPasscodeViewController doesPasscodeExist]) {
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
	
	_typeSwitch.on = [[LTHPasscodeViewController sharedUser] isSimple];
	_touchIDSwitch.on = [[LTHPasscodeViewController sharedUser] allowUnlockWithTouchID];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Demo";
	self.view.backgroundColor = [UIColor whiteColor];
	
	[LTHPasscodeViewController sharedUser].delegate = self;
	[LTHPasscodeViewController sharedUser].maxNumberOfAllowedFailedAttempts = 3;
	
	_changePasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	_enablePasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	_testPasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	_turnOffPasscode = [UIButton buttonWithType: UIButtonTypeCustom];
	
	_enablePasscode.frame = CGRectMake(100, 100, 100, 50);
	_testPasscode.frame = CGRectMake(100, 200, 100, 50);
	_changePasscode.frame = CGRectMake(100, 300, 100, 50);
	_turnOffPasscode.frame = CGRectMake(100, 400, 100, 50);
	
	if ([self isTouchIDAvailable]) {
		_typeLabel = [[UILabel alloc] initWithFrame:(CGRect){230, 190, 60, 30}];
		_typeSwitch = [[UISwitch alloc] initWithFrame:(CGRect){230, 220, 100, 100}];
		_touchIDLabel = [[UILabel alloc] initWithFrame:(CGRect){230, 290, 90, 30}];
		_touchIDSwitch = [[UISwitch alloc] initWithFrame:(CGRect){230, 320, 100, 100}];
		_touchIDLabel.text = @"Touch ID";
		[_touchIDSwitch addTarget:self action:@selector(_touchIDPasscodeType:) forControlEvents:UIControlEventValueChanged];
		[self.view addSubview:_touchIDSwitch];
		[self.view addSubview:_touchIDLabel];
	} else {
		_typeLabel = [[UILabel alloc] initWithFrame:(CGRect){230, 230, 60, 30}];
		_typeSwitch = [[UISwitch alloc] initWithFrame:(CGRect){230, 260, 100, 100}];
	}
	
	
	[_turnOffPasscode setTitle: @"Turn Off" forState: UIControlStateNormal];
	[_changePasscode setTitle: @"Change" forState: UIControlStateNormal];
	[_testPasscode setTitle: @"Test" forState: UIControlStateNormal];
	[_enablePasscode setTitle: @"Enable" forState: UIControlStateNormal];
	_typeLabel.text = @"Simple";
	
	[self _refreshUI];
	
	[_changePasscode addTarget: self action: @selector(_changePasscode) forControlEvents: UIControlEventTouchUpInside];
	[_enablePasscode addTarget: self action: @selector(_enablePasscode) forControlEvents: UIControlEventTouchUpInside];
	[_testPasscode addTarget: self action: @selector(_testPasscode) forControlEvents: UIControlEventTouchUpInside];
	[_turnOffPasscode addTarget: self action: @selector(_turnOffPasscode) forControlEvents: UIControlEventTouchUpInside];
	[_typeSwitch addTarget:self action:@selector(_switchPasscodeType:) forControlEvents:UIControlEventValueChanged];
	
	[self.view addSubview: _changePasscode];
	[self.view addSubview: _turnOffPasscode];
	[self.view addSubview: _testPasscode];
	[self.view addSubview: _enablePasscode];
	[self.view addSubview:_typeSwitch];
	[self.view addSubview:_typeLabel];
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
	// MARK: Please read
	// Please check Issue #16 on the GitHub repo, or this Stack Overflow question, maybe you can give a hand:
	// http://stackoverflow.com/questions/19816142/uialertviews-uiactionsheets-and-keywindow-problems
	// https://github.com/rolandleth/LTHPasscodeViewController/issues/16
	// The issue started with a positioning problem, which is now fixed, but it revealed another kinda hard to fix problem.
	//	UIActionSheet *as = [[UIActionSheet alloc] initWithTitle: @"aa" delegate: nil cancelButtonTitle: @"aa" destructiveButtonTitle:@"ss" otherButtonTitles: nil];
	//	[as showInView: self.view];
	//	UIAlertView *av = [[UIAlertView alloc] initWithTitle: @"aa" message: @"ss" delegate: nil cancelButtonTitle: @"c" otherButtonTitles: nil];
	//	[av show];
}

- (void)_switchPasscodeType:(UISwitch *)sender {
	[[LTHPasscodeViewController sharedUser] setIsSimple:sender.isOn
																		 inViewController:self
																							asModal:YES];
}

- (void)_touchIDPasscodeType:(UISwitch *)sender {
	[[LTHPasscodeViewController sharedUser] setAllowUnlockWithTouchID:sender.isOn];
}

- (void)showLockViewForEnablingPasscode {
	[[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:self
																																					asModal:YES];
}


- (void)showLockViewForTestingPasscode {
	[[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
																													 withLogout:NO
																											 andLogoutTitle:nil];
}


- (void)showLockViewForChangingPasscode {
	[[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController:self asModal:YES];
}


- (void)showLockViewForTurningPasscodeOff {
	[[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:self
																																					 asModal:NO];
}

- (BOOL)isTouchIDAvailable {
	if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
		return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
	}
	return NO;
}

# pragma mark - LTHPasscodeViewController Delegates -

- (void)passcodeViewControllerWillClose {
	NSLog(@"Passcode View Controller Will Be Closed");
	[self _refreshUI];
}

- (void)maxNumberOfFailedAttemptsReached {
	[LTHPasscodeViewController deletePasscodeAndClose];
	NSLog(@"Max Number of Failed Attemps Reached");
}

- (void)passcodeWasEnteredSuccessfully {
	NSLog(@"Passcode Was Entered Successfully");
}

- (void)logoutButtonWasPressed {
	NSLog(@"Logout Button Was Pressed");
}


@end
