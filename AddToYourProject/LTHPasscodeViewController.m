//
//  PasscodeViewController.m
//  ExpensesPlanner
//
//  Created by Roland Leth on 9/4/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHPasscodeViewController.h"
#import "SFHFKeychainUtils.h"

static NSString *const kKeychainUsername = @"demoUser";
static NSString *const kKeychainServiceName = @"demoProject";
static NSString *const kPasscodeCharacter = @"\u2014"; // A longer "-"
static CGFloat const kLabelFontSize = 15.0f;
static CGFloat const kPasscodeFontSize = 33.0f;
static CGFloat const kFontSizeModifier = 1.5f;
static CGFloat const kiPhoneHorizontalGap = 40.0f;
static CGFloat const kAnimationDuration = 0.3f;
// Gaps
// To have a properly centered Passcode, the horizontal gap difference between iPhone and iPad
// Must have the same ratio as the font size difference
#define kHorizontalGap (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? kiPhoneHorizontalGap * kFontSizeModifier : kiPhoneHorizontalGap)
#define kVerticalGap (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 60.0f : 25.0f)
#define kModifierForBottomVerticalGap (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.6f : 3.0f)
// Text Sizes
#define kPasscodeCharWidth [kPasscodeCharacter sizeWithAttributes: @{NSFontAttributeName : kPasscodeFont}].width
#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].width + 60.0f : [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].width + 30.0f)
#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].height
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithAttributes: @{NSFontAttributeName : kLabelFont}].width
// Backgrounds
#define kEnterPasscodeLabelBackgroundColor [UIColor clearColor]
#define kBackgroundColor [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f]
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


#pragma mark - Init
- (id)initForBeingDisplayedAsLockscreen {
	self = [super init];
	if (self) {
		_beingDisplayedAsLockscreen = YES;
	}
	return self;
}

- (id)initForTurningPasscodeOff {
	self = [super init];
	if (self) {
		_isUserTurningPasscodeOff = YES;
	}
	return self;
}


- (id)initForChangingPasscode {
	self = [super init];
	if (self) {
		_isUserChangingPasscode = YES;
	}
	return self;
}


+ (BOOL)passcodeExistsInKeychain {
	return [SFHFKeychainUtils getPasswordForUsername: kKeychainUsername
									  andServiceName: kKeychainServiceName
											   error: nil].length != 0;
}


#pragma mark - View life
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = kBackgroundColor;
	if (_beingDisplayedAsLockscreen) {
		self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
		[UIView animateWithDuration: 0.3f animations: ^{
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y / -1.f);
		}];
	}
	else {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
																							   target: self
																							   action: @selector(cancelAndDismissMe)];
		self.title = @"Enter Passcode";
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
	
	_enterPasscodeLabel.text = _isUserChangingPasscode ? @"Enter your old passcode" : @"Enter your passcode";
	
	_enterPasscodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_failedAttemptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _firstDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	_secondDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	_thirdDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	_fourthDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
	
	// The controller works properly on all devices and orientations, but looks odd on iPhone's landscape.
	// Below is a bit of code to make it look good on iPhone's landscape,
	// but it will make it look a bit worse on iPhone's portrait.
	// Usually, lockscreens on iPhone are kepy portrait only, though.
//	CGFloat yOffsetFromCenter = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
//								 -self.view.frame.size.height * 0.24f :
//								 -self.view.frame.size.height * 0.20f);
	CGFloat yOffsetFromCenter = -self.view.frame.size.height * 0.24f;
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
	if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWasDismissed)])
		[self.delegate performSelector: @selector(passcodeViewControllerWasDismissed)];
	if ([self.delegate respondsToSelector: @selector(refreshUI)])
		[self.delegate performSelector: @selector(refreshUI)];
	if (_beingDisplayedAsLockscreen) {
		[self.view removeFromSuperview];
		[self removeFromParentViewController];
	}
	else {
		[self dismissViewControllerAnimated: YES completion: nil];
	}
}


- (void)dismissMe {
	_isCurrentlyOnScreen = NO;
	[UIView animateWithDuration: 0.3f animations: ^{
		if (_beingDisplayedAsLockscreen) {
			[_passcodeTextField resignFirstResponder];
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
		}
		else {
			// Delete from Keychain
			if (_isUserTurningPasscodeOff) {
				[SFHFKeychainUtils deleteItemForUsername: kKeychainUsername
										  andServiceName: kKeychainServiceName
												   error: nil];
			}
			// Update the Keychain if adding or changing passcode
			else {
				[SFHFKeychainUtils storeUsername: kKeychainUsername
									 andPassword: _tempPasscode
								  forServiceName: kKeychainServiceName
								  updateExisting: YES
										   error: nil];
			}
		}
	} completion: ^(BOOL finished) {
		if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWasDismissed)])
			[self.delegate performSelector: @selector(passcodeViewControllerWasDismissed)];
		if ([self.delegate respondsToSelector: @selector(refreshUI)])
			[self.delegate performSelector: @selector(refreshUI)];
		if (_beingDisplayedAsLockscreen) {
			[self.view removeFromSuperview];
			[self removeFromParentViewController];
		}
		else {
			[self dismissViewControllerAnimated: YES completion: nil];
		}
	}];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField { return !_isCurrentlyOnScreen; }


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
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
		NSString *savedPasscode = [SFHFKeychainUtils getPasswordForUsername: kKeychainUsername andServiceName: kKeychainServiceName error: nil];
		// Entering from Settings. If savedPasscode is empty, it means
		// the user is setting a new Passcode now, or is changing his current Passcode.
		if ((_isUserChangingPasscode  || savedPasscode.length == 0) && !_isUserTurningPasscodeOff) {
			// Either the user is being asked for a new passcode, confirmation comes next,
			// either he is setting up a new passcode, confirmation comes next, still.
			// We need the !_isUserConfirmingPasscode condition, because if he's adding a new Passcode,
			// then savedPasscode is still empty and the condition will always be true, not passing this point.
			if ((_isUserBeingAskedForNewPasscode || savedPasscode.length == 0) && !_isUserConfirmingPasscode) {
				_tempPasscode = typedString;
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
	[transition setDuration: kAnimationDuration];
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
	[transition setDuration: kAnimationDuration];
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
	[transition setDuration: kAnimationDuration];
	[transition setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)resetTextFields {
	_firstDigitTextField.secureTextEntry = NO;
	_secondDigitTextField.secureTextEntry = NO;
	_thirdDigitTextField.secureTextEntry = NO;
	_fourthDigitTextField.secureTextEntry = NO;
}


- (void)resetUI {
	[self resetTextFields];
	_passcodeTextField.text = @"";
	if (_isUserConfirmingPasscode) {
		if (_isUserChangingPasscode) {
			_enterPasscodeLabel.text = @"Re-enter your new passcode";
		}
		else {
			_enterPasscodeLabel.text = @"Re-enter your passcode";
		}
	}
	else {
		_enterPasscodeLabel.text =  @"Enter your new passcode";
	}
}


- (void)resetUIForReEnteringNewPasscode {
	[self resetTextFields];
	_passcodeTextField.text = @"";
	// If there's no passcode saved in Keychain, the user is adding one for the first time, otherwise he's changing his passcode
	NSString *savedPasscode = [SFHFKeychainUtils getPasswordForUsername: kKeychainUsername andServiceName: kKeychainServiceName error: nil];
	_enterPasscodeLabel.text = savedPasscode.length == 0 ? @"Enter your passcode" : @"Enter your new passcode";

	_failedAttemptLabel.hidden = NO;
	_failedAttemptLabel.text = @"Passcodes did not match. Try again.";
	_failedAttemptLabel.backgroundColor = [UIColor clearColor];
	_failedAttemptLabel.layer.borderWidth = 0;
	_failedAttemptLabel.layer.borderColor = [UIColor clearColor].CGColor;
	_failedAttemptLabel.textColor = kLabelTextColor;
}


- (void)denyAccess {
	[self resetTextFields];
	_passcodeTextField.text = @"";
	_failedAttemptLabel.hidden = YES;
	_failedAttempts++;
	if (_failedAttempts == 1) _failedAttemptLabel.text = [NSString stringWithFormat: @"%i Passcode Failed Attempt", _failedAttempts];
	else {
		_failedAttemptLabel.text = [NSString stringWithFormat: @"%i Passcode Failed Attempts", _failedAttempts];
	}
	_failedAttemptLabel.layer.cornerRadius = kFailedAttemptLabelHeight * 0.65f;
	_failedAttemptLabel.hidden = NO;
}


@end
