//
//  PasscodeViewController.m
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHPasscodeViewController.h"
#import "SFHFKeychainUtils.h"

static NSString *const kKeychainPasscode = @"demoPasscode";
static NSString *const kKeychainTimerStart = @"demoPasscodeTimerStart";
static NSString *const kKeychainServiceName = @"demoServiceName";
static NSString *const kUserDefaultsKeyForTimerDuration = @"passcodeTimerDuration";
static NSString *const kPasscodeCharacter = @"\u2014"; // A longer "-"
static CGFloat const kLabelFontSize = 15.0f;
static CGFloat const kPasscodeFontSize = 33.0f;
static CGFloat const kFontSizeModifier = 1.5f;
static CGFloat const kiPhoneHorizontalGap = 40.0f;
static CGFloat const kLockAnimationDuration = 0.15f;
static CGFloat const kSlideAnimationDuration = 0.15f;
// Set to 0 if you want to skip the check. If you don't, nothing happens,
// just maxNumberOfAllowedFailedAttempts protocol method is checked for and called.
static NSInteger const kMaxNumberOfAllowedFailedAttempts = 10;

#define DegreesToRadians(x) ((x) * M_PI / 180.0)
// Gaps
// To have a properly centered Passcode, the horizontal gap difference between iPhone and iPad
// must have the same ratio as the font size difference between them.
#define kHorizontalGap (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? kiPhoneHorizontalGap * kFontSizeModifier : kiPhoneHorizontalGap)
#define kVerticalGap (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 60.0f : 25.0f)
#define kModifierForBottomVerticalGap (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.6f : 3.0f)
// Text Sizes
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
	#define kPasscodeCharWidth [kPasscodeCharacter sizeWithAttributes: @{NSFontAttributeName : kPasscodeFont}].width
	#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].width + 60.0f : [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].width + 30.0f)
	#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].height
	#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].width
#else
// Thanks to Kent Nguyen - https://github.com/kentnguyen
	#define kPasscodeCharWidth [kPasscodeCharacter sizeWithFont:kPasscodeFont].width
	#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithFont:kLabelFont].width + 60.0f : [_failedAttemptLabel.text sizeWithFont:kLabelFont].width + 30.0f)
	#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithFont:kLabelFont].height
	#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithFont:kLabelFont].width
#endif
// Backgrounds
#define kEnterPasscodeLabelBackgroundColor [UIColor clearColor]
#define kBackgroundColor [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f]
#define kCoverViewBackgroundColor [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f]
#define kPasscodeBackgroundColor [UIColor clearColor]
#define kFailedAttemptLabelBackgroundColor [UIColor colorWithRed:0.8f green:0.1f blue:0.2f alpha:1.000f]
// Fonts
#define kLabelFont (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [UIFont fontWithName: @"AvenirNext-Regular" size: kLabelFontSize * kFontSizeModifier] : [UIFont fontWithName: @"AvenirNext-Regular" size: kLabelFontSize])
#define kPasscodeFont (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [UIFont fontWithName: @"AvenirNext-Regular" size: kPasscodeFontSize * kFontSizeModifier] : [UIFont fontWithName: @"AvenirNext-Regular" size: kPasscodeFontSize])
// Text Colors
#define kLabelTextColor [UIColor colorWithWhite:0.31f alpha:1.0f]
#define kPasscodeTextColor [UIColor colorWithWhite:0.31f alpha:1.0f]
#define kFailedAttemptLabelTextColor [UIColor whiteColor]

@implementation LTHPasscodeViewController


#pragma mark - Class methods
+ (BOOL)passcodeExistsInKeychain {
	return [SFHFKeychainUtils getPasswordForUsername: kKeychainPasscode
									  andServiceName: kKeychainServiceName
											   error: nil].length != 0;
}


+ (CGFloat)timerDuration {
	return [[NSUserDefaults standardUserDefaults] floatForKey: kUserDefaultsKeyForTimerDuration];
}


+ (CGFloat)timerStartTime {
	NSString *keychainValue = [SFHFKeychainUtils getPasswordForUsername: kKeychainTimerStart
														 andServiceName: kKeychainServiceName
																  error: nil];
	if (!keychainValue) return -1;
	return keychainValue.floatValue;
}


+ (void)saveTimerStartTime {
	[SFHFKeychainUtils storeUsername: kKeychainTimerStart
						 andPassword: [NSString stringWithFormat: @"%f", [NSDate timeIntervalSinceReferenceDate]]
					  forServiceName: kKeychainServiceName
					  updateExisting: YES
							   error: nil];
}


+ (BOOL)didPasscodeTimerEnd {
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	// startTime wasn't saved yet (first app use and it crashed, phone force closed, etc) if it returns -1.
	if (now - [self timerStartTime] >= [self timerDuration] || [self timerStartTime] == -1) return YES;
	return NO;
}


+ (void)deletePasscodeFromKeychain {
	[SFHFKeychainUtils deleteItemForUsername: kKeychainPasscode
							  andServiceName: kKeychainServiceName
									   error: nil];
}


#pragma mark - View life
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = kBackgroundColor;
	if (!_beingDisplayedAsLockscreen) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
																							   target: self
																							   action: @selector(cancelAndDismissMe)];
		self.title = NSLocalizedString(@"Enter Passcode", @"");
	}
	
	_isCurrentlyOnScreen = YES;
	_failedAttempts = 0;
	_animatingView = [[UIView alloc] initWithFrame: self.view.frame];
	[self.view addSubview: _animatingView];
	
	_enterPasscodeLabel = [[UILabel alloc] initWithFrame: CGRectZero];
	_enterPasscodeLabel.backgroundColor = kEnterPasscodeLabelBackgroundColor;
	_enterPasscodeLabel.textColor = kLabelTextColor;
	_enterPasscodeLabel.font = kLabelFont;
	_enterPasscodeLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _enterPasscodeLabel];
	
	// It is also used to display the "Passcodes did not match" error message if the user fails to confirm the passcode.
	_failedAttemptLabel = [[UILabel alloc] initWithFrame: CGRectZero];
	_failedAttemptLabel.text = @"1 Passcode Failed Attempt";
	_failedAttemptLabel.backgroundColor	= kFailedAttemptLabelBackgroundColor;
	_failedAttemptLabel.hidden = YES;
	_failedAttemptLabel.textColor = kFailedAttemptLabelTextColor;
	_failedAttemptLabel.font = kLabelFont;
	_failedAttemptLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _failedAttemptLabel];
	
	_firstDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _firstDigitTextField.backgroundColor = kPasscodeBackgroundColor;
    _firstDigitTextField.textAlignment = NSTextAlignmentCenter;
	_firstDigitTextField.text = kPasscodeCharacter;
	_firstDigitTextField.textColor = kPasscodeTextColor;
	_firstDigitTextField.font = kPasscodeFont;
	_firstDigitTextField.secureTextEntry = NO;
    [_firstDigitTextField setBorderStyle:UITextBorderStyleNone];
	_firstDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_firstDigitTextField];
	
	_secondDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _secondDigitTextField.backgroundColor = kPasscodeBackgroundColor;
    _secondDigitTextField.textAlignment = NSTextAlignmentCenter;
	_secondDigitTextField.text = kPasscodeCharacter;
	_secondDigitTextField.textColor = kPasscodeTextColor;
	_secondDigitTextField.font = kPasscodeFont;
	_secondDigitTextField.secureTextEntry = NO;
    [_secondDigitTextField setBorderStyle:UITextBorderStyleNone];
	_secondDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_secondDigitTextField];
	
	_thirdDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _thirdDigitTextField.backgroundColor = kPasscodeBackgroundColor;
    _thirdDigitTextField.textAlignment = NSTextAlignmentCenter;
	_thirdDigitTextField.text = kPasscodeCharacter;
	_thirdDigitTextField.textColor = kPasscodeTextColor;
	_thirdDigitTextField.font = kPasscodeFont;
	_thirdDigitTextField.secureTextEntry = NO;
    [_thirdDigitTextField setBorderStyle:UITextBorderStyleNone];
	_thirdDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_thirdDigitTextField];
	
	_fourthDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _fourthDigitTextField.backgroundColor = kPasscodeBackgroundColor;
    _fourthDigitTextField.textAlignment = NSTextAlignmentCenter;
	_fourthDigitTextField.text = kPasscodeCharacter;
	_fourthDigitTextField.textColor = kPasscodeTextColor;
	_fourthDigitTextField.font = kPasscodeFont;
	_fourthDigitTextField.secureTextEntry = NO;
    [_fourthDigitTextField setBorderStyle:UITextBorderStyleNone];
	_fourthDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_fourthDigitTextField];
	
	_passcodeTextField = [[UITextField alloc] initWithFrame: CGRectZero];
	_passcodeTextField.hidden = YES;
	_passcodeTextField.delegate = self;
	_passcodeTextField.keyboardType = UIKeyboardTypeNumberPad;
	[_passcodeTextField becomeFirstResponder];
    [_animatingView addSubview:_passcodeTextField];
	
	_enterPasscodeLabel.text = _isUserChangingPasscode ? NSLocalizedString(@"Enter your old passcode", @"") : NSLocalizedString(@"Enter your passcode", @"");
	
	_enterPasscodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_failedAttemptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _firstDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	_secondDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	_thirdDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	_fourthDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	
	// MARK: Please read
	// The controller works properly on all devices and orientations, but looks odd on iPhone's landscape.
	// Usually, lockscreens on iPhone are kept portrait-only, though. It also doesn't fit inside a modal when landscape.
	// That's why only portrait is selected for iPhone's supported orientations.
	// Modify this to fit your needs.
	
	CGFloat yOffsetFromCenter = -self.view.frame.size.height * 0.24;
	NSLayoutConstraint *enterPasscodeConstraintCenterX = [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
																					  attribute: NSLayoutAttributeCenterX
																					  relatedBy: NSLayoutRelationEqual
																						 toItem: self.view
																					  attribute: NSLayoutAttributeCenterX
																					 multiplier: 1.0f
																					   constant: 0.0f];
	NSLayoutConstraint *enterPasscodeConstraintCenterY = [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
																					  attribute: NSLayoutAttributeCenterY
																					  relatedBy: NSLayoutRelationEqual
																						 toItem: self.view
																					  attribute: NSLayoutAttributeCenterY
																					 multiplier: 1.0f
																					   constant: yOffsetFromCenter];
    [self.view addConstraint: enterPasscodeConstraintCenterX];
    [self.view addConstraint: enterPasscodeConstraintCenterY];
	
	NSLayoutConstraint *firstDigitX = [NSLayoutConstraint constraintWithItem: _firstDigitTextField
																   attribute: NSLayoutAttributeLeft
																   relatedBy: NSLayoutRelationEqual
																	  toItem: self.view
																   attribute: NSLayoutAttributeCenterX
																  multiplier: 1.0f
																	constant: - kHorizontalGap * 1.5f - 2.0f];
	NSLayoutConstraint *secondDigitX = [NSLayoutConstraint constraintWithItem: _secondDigitTextField
																	attribute: NSLayoutAttributeLeft
																	relatedBy: NSLayoutRelationEqual
																	   toItem: self.view
																	attribute: NSLayoutAttributeCenterX
																   multiplier: 1.0f
																	 constant: - kHorizontalGap * 2/3 - 2.0f];
	NSLayoutConstraint *thirdDigitX = [NSLayoutConstraint constraintWithItem: _thirdDigitTextField
																   attribute: NSLayoutAttributeLeft
																   relatedBy: NSLayoutRelationEqual
																	  toItem: self.view
																   attribute: NSLayoutAttributeCenterX
																  multiplier: 1.0f
																	constant: kHorizontalGap * 1/6 - 2.0f];
	NSLayoutConstraint *fourthDigitX = [NSLayoutConstraint constraintWithItem: _fourthDigitTextField
																	attribute: NSLayoutAttributeLeft
																	relatedBy: NSLayoutRelationEqual
																	   toItem: self.view
																	attribute: NSLayoutAttributeCenterX
																   multiplier: 1.0f
																	 constant: kHorizontalGap - 2.0f];
	NSLayoutConstraint *firstDigitY = [NSLayoutConstraint constraintWithItem: _firstDigitTextField
																   attribute: NSLayoutAttributeCenterY
																   relatedBy: NSLayoutRelationEqual
																	  toItem: _enterPasscodeLabel
																   attribute: NSLayoutAttributeBottom
																  multiplier: 1.0f
																	constant: kVerticalGap];
	NSLayoutConstraint *secondDigitY = [NSLayoutConstraint constraintWithItem: _secondDigitTextField
																	attribute: NSLayoutAttributeCenterY
																	relatedBy: NSLayoutRelationEqual
																	   toItem: _enterPasscodeLabel
																	attribute: NSLayoutAttributeBottom
																   multiplier: 1.0f
																	 constant: kVerticalGap];
	NSLayoutConstraint *thirdDigitY = [NSLayoutConstraint constraintWithItem: _thirdDigitTextField
																   attribute: NSLayoutAttributeCenterY
																   relatedBy: NSLayoutRelationEqual
																	  toItem: _enterPasscodeLabel
																   attribute: NSLayoutAttributeBottom
																  multiplier: 1.0f
																	constant: kVerticalGap];
	NSLayoutConstraint *fourthDigitY = [NSLayoutConstraint constraintWithItem: _fourthDigitTextField
																	attribute: NSLayoutAttributeCenterY
																	relatedBy: NSLayoutRelationEqual
																	   toItem: _enterPasscodeLabel
																	attribute: NSLayoutAttributeBottom
																   multiplier: 1.0f
																	 constant: kVerticalGap];
	[self.view addConstraint:firstDigitX];
	[self.view addConstraint:secondDigitX];
	[self.view addConstraint:thirdDigitX];
	[self.view addConstraint:fourthDigitX];
	[self.view addConstraint:firstDigitY];
	[self.view addConstraint:secondDigitY];
	[self.view addConstraint:thirdDigitY];
	[self.view addConstraint:fourthDigitY];
	
    NSLayoutConstraint *failedAttemptLabelCenterX = [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
																				 attribute: NSLayoutAttributeCenterX
																				 relatedBy: NSLayoutRelationEqual
																					toItem: self.view
																				 attribute: NSLayoutAttributeCenterX
																				multiplier: 1.0f
																				  constant: 0.0f];
	NSLayoutConstraint *failedAttemptLabelCenterY = [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
																				 attribute: NSLayoutAttributeCenterY
																				 relatedBy: NSLayoutRelationEqual
																					toItem: _enterPasscodeLabel
																				 attribute: NSLayoutAttributeBottom
																				multiplier: 1.0f
																				  constant: kVerticalGap * kModifierForBottomVerticalGap - 2.0f];
	NSLayoutConstraint *failedAttemptLabelWidth = [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
																			   attribute: NSLayoutAttributeWidth
																			   relatedBy: NSLayoutRelationGreaterThanOrEqual
																				  toItem: nil
																			   attribute: NSLayoutAttributeNotAnAttribute
																			  multiplier: 1.0f
																				constant: kFailedAttemptLabelWidth];
	NSLayoutConstraint *failedAttemptLabelHeight = [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
																				attribute: NSLayoutAttributeHeight
																				relatedBy: NSLayoutRelationEqual
																				   toItem: nil
																				attribute: NSLayoutAttributeNotAnAttribute
																			   multiplier: 1.0f
																				 constant: kFailedAttemptLabelHeight + 6.0f];
	[self.view addConstraint:failedAttemptLabelCenterX];
	[self.view addConstraint:failedAttemptLabelCenterY];
	[self.view addConstraint:failedAttemptLabelWidth];
	[self.view addConstraint:failedAttemptLabelHeight];
}


- (void)cancelAndDismissMe {
	_isCurrentlyOnScreen = NO;
	[_passcodeTextField resignFirstResponder];
	_isUserBeingAskedForNewPasscode = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
	_isUserTurningPasscodeOff = NO;
	[self resetUI];
	
	if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWasDismissed)])
		[self.delegate performSelector: @selector(passcodeViewControllerWasDismissed)];
	// Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"dismissPasscodeViewController"
//														object: self
//													  userInfo: nil];
	[self dismissViewControllerAnimated: YES completion: nil];
}


- (void)dismissMe {
	_isCurrentlyOnScreen = NO;
	[self resetUI];
	[_passcodeTextField resignFirstResponder];
	[UIView animateWithDuration: kLockAnimationDuration animations: ^{
		if (_beingDisplayedAsLockscreen) {
			if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
				self.view.center = CGPointMake(self.view.center.x * -1.f, self.view.center.y);
			}
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
				self.view.center = CGPointMake(self.view.center.x * 2.f, self.view.center.y);
			}
			else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
				self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
			}
			else {
				self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
			}
		}
		else {
			// Delete from Keychain
			if (_isUserTurningPasscodeOff) {
				[LTHPasscodeViewController deletePasscodeFromKeychain];
			}
			// Update the Keychain if adding or changing passcode
			else {
				[SFHFKeychainUtils storeUsername: kKeychainPasscode
									 andPassword: _tempPasscode
								  forServiceName: kKeychainServiceName
								  updateExisting: YES
										   error: nil];
			}
		}
	} completion: ^(BOOL finished) {
		if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWasDismissed)])
			[self.delegate performSelector: @selector(passcodeViewControllerWasDismissed)];
		// Or, if you prefer by notifications:
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"dismissPasscodeViewController"
//															object: self
//														  userInfo: nil];
		if (_beingDisplayedAsLockscreen) {
			[self.view removeFromSuperview];
			[self removeFromParentViewController];
		}
		else {
			[self dismissViewControllerAnimated: YES completion: nil];
		}
	}];
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIApplicationDidChangeStatusBarOrientationNotification
												  object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIApplicationDidChangeStatusBarFrameNotification
												  object: nil];
}


#pragma mark - Displaying
- (void)showLockscreenWithAnimation:(BOOL)animated {
	// In case the user leaves the app while changing/disabling Passcode.
	if (!_beingDisplayedAsLockscreen) [self cancelAndDismissMe];
	[self prepareAsLockscreen];
	// In case the user leaves the app while the lockscreen is already active.
	if (!_isCurrentlyOnScreen) {
		// MARK: Window changes. Please read:
		// Usually, the app's window is the first on the stack. I'm doing this because if an alertView or actionSheet
		// is open when presenting the lockscreen causes problems, because the av/as has it's own window that replaces the keyWindow
		// and due to how Apple handles said window internally.
		// Currently the lockscreen appears behind the av/as, which is the best compromise for now.
		// You can read and/or give a hand following one of the links below
		// http://stackoverflow.com/questions/19816142/uialertviews-uiactionsheets-and-keywindow-problems
		// https://github.com/rolandleth/LTHPasscodeViewController/issues/16
		// Usually not more than one window is needed, but your needs may vary; modify below.
//		UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
		UIWindow *mainWindow = [UIApplication sharedApplication].windows[0];
		[mainWindow addSubview: self.view];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(statusBarFrameOrOrientationChanged:)
													 name:UIApplicationDidChangeStatusBarOrientationNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(statusBarFrameOrOrientationChanged:)
													 name:UIApplicationDidChangeStatusBarFrameNotification
												   object:nil];
		[mainWindow.rootViewController addChildViewController: self];
		// All this hassle because a view added to UIWindow does not rotate automatically
		// and if we would have added the view anywhere else, it wouldn't display properly
		// (having a modal on screen when the user leaves the app, for example).
		[self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
		CGPoint newCenter;
		if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
			self.view.center = CGPointMake(self.view.center.x * -1.f, self.view.center.y);
			newCenter = CGPointMake(mainWindow.center.x - self.navigationController.navigationBar.frame.size.height / 2,
									mainWindow.center.y);
		}
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
			self.view.center = CGPointMake(self.view.center.x * 2.f, self.view.center.y);
			newCenter = CGPointMake(mainWindow.center.x + self.navigationController.navigationBar.frame.size.height / 2,
									mainWindow.center.y);
		}
		else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
			newCenter = CGPointMake(mainWindow.center.x,
									mainWindow.center.y - self.navigationController.navigationBar.frame.size.height / 2);
		}
		else {
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
			newCenter = CGPointMake(mainWindow.center.x,
									mainWindow.center.y + self.navigationController.navigationBar.frame.size.height / 2);
		}
		if (animated) {
			[UIView animateWithDuration: kLockAnimationDuration animations: ^{
				self.view.center = newCenter;
			}];
		} else {
			self.view.center = newCenter;
		}
		_isCurrentlyOnScreen = YES;
	}
}


- (void)prepareNavigationControllerWithController:(UIViewController *)viewController {
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: self];
	[viewController presentViewController: navController animated: YES completion: nil];
	[self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
																						   target: self
																						   action: @selector(cancelAndDismissMe)];
}


- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController {
	[self prepareForEnablingPasscode];
	[self prepareNavigationControllerWithController: viewController];
	self.title = NSLocalizedString(@"Enable Passcode", @"");
}


- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController {
	[self prepareForChangingPasscode];
	[self prepareNavigationControllerWithController: viewController];
	self.title = NSLocalizedString(@"Change Passcode", @"");
}


- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController {
	[self prepareForTurningOffPasscode];
	[self prepareNavigationControllerWithController: viewController];
	self.title = NSLocalizedString(@"Turn Off Passcode", @"");
}


#pragma mark - Preparing
- (void)prepareAsLockscreen {
	_beingDisplayedAsLockscreen = YES;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
	[self resetUI];
}


- (void)prepareForChangingPasscode {
	_isCurrentlyOnScreen = YES;
	_beingDisplayedAsLockscreen = NO;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
	[self resetUI];
}


- (void)prepareForTurningOffPasscode {
	_isCurrentlyOnScreen = YES;
	_beingDisplayedAsLockscreen = NO;
	_isUserTurningPasscodeOff = YES;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
	[self resetUI];
}


- (void)prepareForEnablingPasscode {
	_isCurrentlyOnScreen = YES;
	_beingDisplayedAsLockscreen = NO;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = YES;
	[self resetUI];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return !_isCurrentlyOnScreen;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([string isEqualToString: @"\n"]) return NO;
	
	NSString *typedString = [textField.text stringByReplacingCharactersInRange: range
																	withString: string];
	if (typedString.length >= 1) _firstDigitTextField.secureTextEntry = YES;
	else _firstDigitTextField.secureTextEntry = NO;
	if (typedString.length >= 2) _secondDigitTextField.secureTextEntry = YES;
	else _secondDigitTextField.secureTextEntry = NO;
	if (typedString.length >= 3) _thirdDigitTextField.secureTextEntry = YES;
	else _thirdDigitTextField.secureTextEntry = NO;
	if (typedString.length == 4) _fourthDigitTextField.secureTextEntry = YES;
	else _fourthDigitTextField.secureTextEntry = NO;
	
	if (typedString.length == 4) {
		NSString *savedPasscode = [SFHFKeychainUtils getPasswordForUsername: kKeychainPasscode
															 andServiceName: kKeychainServiceName
																	  error: nil];
		// Entering from Settings. If savedPasscode is empty, it means
		// the user is setting a new Passcode now, or is changing his current Passcode.
		if ((_isUserChangingPasscode  || savedPasscode.length == 0) && !_isUserTurningPasscodeOff) {
			// Either the user is being asked for a new passcode, confirmation comes next,
			// either he is setting up a new passcode, confirmation comes next, still.
			// We need the !_isUserConfirmingPasscode condition, because if he's adding a new Passcode,
			// then savedPasscode is still empty and the condition will always be true, not passing this point.
			if ((_isUserBeingAskedForNewPasscode || savedPasscode.length == 0) && !_isUserConfirmingPasscode) {
				_tempPasscode = typedString;
				// The delay is to give time for the last bullet to appear
				[self performSelector: @selector(askForConfirmationPasscode) withObject: nil afterDelay: 0.15f];
			}
			// User entered his Passcode correctly and we are at the confirming screen.
			else if (_isUserConfirmingPasscode) {
				// User entered the confirmation Passcode correctly
				if ([typedString isEqualToString: _tempPasscode]) {
					[self dismissMe];
				}
				// User entered the confirmation Passcode incorrectly, start over.
				else {
					[self performSelector: @selector(reAskForNewPasscode) withObject: nil afterDelay: 0.15f];
				}
			}
			// Changing Passcode and the entered Passcode is correct.
			else if ([typedString isEqualToString: savedPasscode]){
				[self performSelector: @selector(askForNewPasscode) withObject: nil afterDelay: 0.15f];
				_failedAttempts = 0;
			}
			// Acting as lockscreen and the entered Passcode is incorrect.
			else {
				[self performSelector: @selector(denyAccess) withObject: nil afterDelay: 0.15f];
				return NO;
			}
		}
		// App launch/Turning passcode off: Passcode OK -> dismiss, Passcode incorrect -> deny access.
		else {
			if ([typedString isEqualToString: savedPasscode]) [self dismissMe];
			else {
				[self performSelector: @selector(denyAccess) withObject: nil afterDelay: 0.15f];
				return NO;
			}
		}
	}
	
	if (typedString.length > 4) return NO;
	
	return YES;
}


#pragma mark - Actions
- (void)askForNewPasscode {
	_isUserBeingAskedForNewPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_failedAttemptLabel.hidden = YES;
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(resetUI) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: kSlideAnimationDuration];
	[transition setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)reAskForNewPasscode {
	_isUserBeingAskedForNewPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_tempPasscode = @"";
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(resetUIForReEnteringNewPasscode) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: kSlideAnimationDuration];
	[transition setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)askForConfirmationPasscode {
	_isUserBeingAskedForNewPasscode = NO;
	_isUserConfirmingPasscode = YES;
	_failedAttemptLabel.hidden = YES;
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(resetUI) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: kSlideAnimationDuration];
	[transition setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)resetTextFields {
	if (![_passcodeTextField isFirstResponder])
		[_passcodeTextField becomeFirstResponder];
	_firstDigitTextField.secureTextEntry = NO;
	_secondDigitTextField.secureTextEntry = NO;
	_thirdDigitTextField.secureTextEntry = NO;
	_fourthDigitTextField.secureTextEntry = NO;
}


- (void)resetUI {
	[self resetTextFields];
	_failedAttemptLabel.backgroundColor	= kFailedAttemptLabelBackgroundColor;
	_failedAttemptLabel.textColor = kFailedAttemptLabelTextColor;
	_failedAttempts = 0;
	_failedAttemptLabel.hidden = YES;
	_passcodeTextField.text = @"";
	if (_isUserConfirmingPasscode) {
		if (_isUserEnablingPasscode) _enterPasscodeLabel.text = NSLocalizedString(@"Re-enter your passcode", @"");
		else if (_isUserChangingPasscode) _enterPasscodeLabel.text = NSLocalizedString(@"Re-enter your new passcode", @"");
	}
	else if (_isUserBeingAskedForNewPasscode) {
		if (_isUserEnablingPasscode || _isUserChangingPasscode) {
			_enterPasscodeLabel.text = NSLocalizedString(@"Enter your new passcode", @"");
		}
	}
	else _enterPasscodeLabel.text = NSLocalizedString(@"Enter your passcode", @"");
}


- (void)resetUIForReEnteringNewPasscode {
	[self resetTextFields];
	_passcodeTextField.text = @"";
	// If there's no passcode saved in Keychain, the user is adding one for the first time, otherwise he's changing his passcode.
	NSString *savedPasscode = [SFHFKeychainUtils getPasswordForUsername: kKeychainPasscode
														 andServiceName: kKeychainServiceName
																  error: nil];
	_enterPasscodeLabel.text = savedPasscode.length == 0 ? NSLocalizedString(@"Enter your passcode", @"") : NSLocalizedString(@"Enter your new passcode", @"");
	
	_failedAttemptLabel.hidden = NO;
	_failedAttemptLabel.text = NSLocalizedString(@"Passcodes did not match. Try again.", @"");
	_failedAttemptLabel.backgroundColor = [UIColor clearColor];
	_failedAttemptLabel.layer.borderWidth = 0;
	_failedAttemptLabel.layer.borderColor = [UIColor clearColor].CGColor;
	_failedAttemptLabel.textColor = kLabelTextColor;
}


- (void)denyAccess {
	[self resetTextFields];
	_passcodeTextField.text = @"";
	_failedAttempts++;
	
	if (kMaxNumberOfAllowedFailedAttempts > 0 &&
		_failedAttempts == kMaxNumberOfAllowedFailedAttempts &&
		[self.delegate respondsToSelector: @selector(maxNumberOfFailedAttemptsReached)])
		[self.delegate maxNumberOfFailedAttemptsReached];
//	Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"maxNumberOfFailedAttemptsReached"
//														object: self
//													  userInfo: nil];
	
	if (_failedAttempts == 1) _failedAttemptLabel.text = NSLocalizedString(@"1 Passcode Failed Attempt", @"");
	else {
		_failedAttemptLabel.text = [NSString stringWithFormat: NSLocalizedString(@"%i Passcode Failed Attempts", @""), _failedAttempts];
	}
	_failedAttemptLabel.layer.cornerRadius = kFailedAttemptLabelHeight * 0.65f;
	_failedAttemptLabel.hidden = NO;
}


#pragma mark - Notification Observers
- (void)applicationDidEnterBackground {
	if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		if ([_passcodeTextField isFirstResponder]) [_passcodeTextField resignFirstResponder];
		// Without animation because otherwise it won't come down fast enough,
		// so inside iOS' multitasking view the app won't be covered by anything.
		if ([LTHPasscodeViewController timerDuration] == 0) [self showLockscreenWithAnimation: NO];
		else {
			_coverView.hidden = NO;
			if (![[UIApplication sharedApplication].keyWindow viewWithTag: 99]) [[UIApplication sharedApplication].keyWindow addSubview: _coverView];
		}
	}
}


- (void)applicationDidBecomeActive {
	_coverView.hidden = YES;
}


- (void)applicationWillEnterForeground {
	if ([LTHPasscodeViewController passcodeExistsInKeychain] &&
		[LTHPasscodeViewController didPasscodeTimerEnd] &&
		![LTHPasscodeViewController sharedUser].isCurrentlyOnScreen) {
		[[LTHPasscodeViewController sharedUser] showLockscreenWithAnimation: YES];
	}
}


- (void)applicationWillResignActive {
	if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		[LTHPasscodeViewController saveTimerStartTime];
	}
}


#pragma mark - Init
+ (LTHPasscodeViewController *)sharedUser {
    __strong static LTHPasscodeViewController *sharedObject = nil;
	
	if (sharedObject) {
		return sharedObject;
	}
	
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedObject = [[LTHPasscodeViewController alloc] init]; // or some other init method
	});
	
	return sharedObject;
}


- (id)init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(applicationDidEnterBackground)
													 name: UIApplicationDidEnterBackgroundNotification
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(applicationWillResignActive)
													 name: UIApplicationWillResignActiveNotification
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(applicationDidBecomeActive)
													 name: UIApplicationDidBecomeActiveNotification
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(applicationWillEnterForeground)
													 name: UIApplicationWillEnterForegroundNotification
												   object: nil];
		
		_coverView = [[UIView alloc] initWithFrame: CGRectZero];
		_coverView.backgroundColor = kCoverViewBackgroundColor;
		_coverView.frame = self.view.frame;
		_coverView.userInteractionEnabled = NO;
		_coverView.tag = 99;
		_coverView.hidden = YES;
		[[UIApplication sharedApplication].keyWindow addSubview: _coverView];
	}
	return self;
}


- (NSUInteger)supportedInterfaceOrientations {
	if (_beingDisplayedAsLockscreen) return UIInterfaceOrientationMaskAll;
	// I'll be honest and mention I have no idea why this line of code below works.
	// Without it, if you present the passcode view as lockscreen (directly on the window)
	// and then inside of a modal, the orientation will be wrong.
	
	// Feel free to explain why, I'd be more than grateful :)
	return UIInterfaceOrientationPortraitUpsideDown;
}


// All of the rotation handling is thanks to Håvard Fossli's - https://github.com/hfossli
// answer: http://stackoverflow.com/a/4960988/793916
#pragma mark - Handling rotation
- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification {
    /*
     This notification is most likely triggered inside an animation block,
     therefore no animation is needed to perform this nice transition.
     */
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}


// And to his AGWindowView: https://github.com/hfossli/AGWindowView
// Without the 'desiredOrientation' method, using showLockscreen in one orientation,
// then presenting it inside a modal in another orientation would display the view in the first orientation.
- (UIInterfaceOrientation)desiredOrientation {
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UIInterfaceOrientationMask statusBarOrientationAsMask = UIInterfaceOrientationMaskFromOrientation(statusBarOrientation);
    if(self.supportedInterfaceOrientations & statusBarOrientationAsMask) {
        return statusBarOrientation;
    }
    else {
        if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskPortrait) {
            return UIInterfaceOrientationPortrait;
        }
        else if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeLeft) {
            return UIInterfaceOrientationLandscapeLeft;
        }
        else if(self.supportedInterfaceOrientations & UIInterfaceOrientationMaskLandscapeRight) {
            return UIInterfaceOrientationLandscapeRight;
        }
        else {
            return UIInterfaceOrientationPortraitUpsideDown;
        }
    }
}


- (void)rotateAccordingToStatusBarOrientationAndSupportedOrientations {
	UIInterfaceOrientation orientation = [self desiredOrientation];
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation(orientation);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
	
    [self setIfNotEqualTransform: transform
						   frame: self.view.window.bounds];
}


- (void)setIfNotEqualTransform:(CGAffineTransform)transform frame:(CGRect)frame {
    if(!CGAffineTransformEqualToTransform(self.view.transform, transform)) {
        self.view.transform = transform;
    }
    if(!CGRectEqualToRect(self.view.frame, frame)) {
        self.view.frame = frame;
    }
}


+ (CGFloat)getStatusBarHeight {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        return [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}


CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation) {
    CGFloat angle;
	
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        default:
            angle = 0.0;
            break;
    }
	
    return angle;
}

UIInterfaceOrientationMask UIInterfaceOrientationMaskFromOrientation(UIInterfaceOrientation orientation) {
    return 1 << orientation;
}


@end
