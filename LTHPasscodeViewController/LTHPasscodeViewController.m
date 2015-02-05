//
//  PasscodeViewController.m
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHPasscodeViewController.h"
#import "SFHFKeychainUtils.h"
#import "BWAnalytics.h"

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define kPasscodeCharWidth [_passcodeCharacter sizeWithAttributes: @{NSFontAttributeName : _passcodeFont}].width
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width
#else
// Thanks to Kent Nguyen - https://github.com/kentnguyen
#define kPasscodeCharWidth [_passcodeCharacter sizeWithFont:_passcodeFont].width
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithFont:_labelFont].width
#endif

static const CGFloat kTopSpacing4Inch = 80.0f;
static const CGFloat kTopSpacing35Inch = 30.0f;
static const CGFloat kVerticalGap4Inch = 54.0f;
static const CGFloat kVerticalGap35Inch = 5.0f;
static const CGFloat kDigitHorizontalGap = 40.0f;
static const CGFloat kFailedAttemptLabelYOffset = -216.0f;
static const CGFloat kFailedAttemptLabelHeight = 22.0f;

@interface LTHPasscodeViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIView      *coverView;
@property (nonatomic, strong) UIView      *animatingView;
@property (nonatomic, strong) UIView      *complexPasscodeOverlayView;

@property (nonatomic, strong) UITextField *passcodeTextField;
@property (nonatomic, strong) UITextField *firstDigitTextField;
@property (nonatomic, strong) UITextField *secondDigitTextField;
@property (nonatomic, strong) UITextField *thirdDigitTextField;
@property (nonatomic, strong) UITextField *fourthDigitTextField;

@property (nonatomic, strong) UILabel     *failedAttemptLabel;
@property (nonatomic, strong) UILabel     *enterPasscodeLabel;
@property (nonatomic, strong) UIButton    *forgottenPasswordButton;

@property (nonatomic, strong) NSString    *tempPasscode;
@property (nonatomic, assign) NSInteger   failedAttempts;

@property (nonatomic, assign) BOOL        usesKeychain;
@property (nonatomic, assign) BOOL        displayedAsModal;
@property (nonatomic, assign) BOOL        displayedAsLockScreen;
@property (nonatomic, assign) BOOL        isSimple;// YES by default
@property (nonatomic, assign) BOOL        isUserConfirmingPasscode;
@property (nonatomic, assign) BOOL        isUserBeingAskedForNewPasscode;
@property (nonatomic, assign) BOOL        isUserTurningPasscodeOff;
@property (nonatomic, assign) BOOL        isUserChangingPasscode;
@property (nonatomic, assign) BOOL        isUserEnablingPasscode;
@property (nonatomic, assign) BOOL        isUserSwitchingBetweenPasscodeModes;// simple/complex
@property (nonatomic, assign) BOOL        timerStartInSeconds;
@end

@implementation LTHPasscodeViewController


#pragma mark - Public, class methods
+ (BOOL)passcodeExistsInKeychain {
	return [self doesPasscodeExist];
}


+ (BOOL)doesPasscodeExist {
	return [[LTHPasscodeViewController sharedUser] _doesPasscodeExist];
}


+ (NSString *)passcode {
	return [[LTHPasscodeViewController sharedUser] _passcode];
}

+ (void)deletePasscodeFromKeychain {
	[[LTHPasscodeViewController sharedUser] _deletePasscode];
}


+ (void)deletePasscode {
	[[LTHPasscodeViewController sharedUser] _deletePasscode];
}


+ (void)useKeychain:(BOOL)useKeychain {
    [[LTHPasscodeViewController sharedUser] _useKeychain:useKeychain];
}


#pragma mark - Private methods
- (void)_useKeychain:(BOOL)useKeychain {
    _usesKeychain = useKeychain;
}


- (BOOL)_doesPasscodeExist {
	return [self _passcode].length != 0;
}

- (void)_deletePasscode {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(deletePasscode)]) {
        [self.delegate deletePasscode];
        
        return;
    }
    
	[SFHFKeychainUtils deleteItemForUsername:_keychainPasscodeUsername
							  andServiceName:_keychainServiceName
									   error:nil];
	
	[[BWAnalytics sharedInstance] trackEventWithCategory:kEventCategoryConfiguration action:kEventActionDisabledPasscode];
}


- (void)_savePasscode:(NSString *)passcode {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(savePasscode:)]) {
        [self.delegate savePasscode:passcode];
        
        return;
    }
    
    [SFHFKeychainUtils storeUsername:_keychainPasscodeUsername
                         andPassword:passcode
                      forServiceName:_keychainServiceName
                      updateExisting:YES
                               error:nil];
	
	[[BWAnalytics sharedInstance] trackEventWithCategory:kEventCategoryConfiguration action:kEventActionChangedOrEnabledPasscode];
}


- (NSString *)_passcode {
	if (!_usesKeychain &&
		[self.delegate respondsToSelector:@selector(passcode)]) {
		return [self.delegate passcode];
	}
	
	return [SFHFKeychainUtils getPasswordForUsername:_keychainPasscodeUsername
									  andServiceName:_keychainServiceName
											   error:nil];
}


#pragma mark - View life
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = _backgroundColor;
    
	_failedAttempts = 0;
	_animatingView = [[UIView alloc] initWithFrame: self.view.frame];
	[self.view addSubview: _animatingView];
    
	[self _setupViews];
    [self _setupLabels];
    [self _setupDigitFields];
	
	_passcodeTextField = [[UITextField alloc] initWithFrame: CGRectZero];
	_passcodeTextField.delegate = self;
    _passcodeTextField.secureTextEntry = YES;
    _passcodeTextField.translatesAutoresizingMaskIntoConstraints = NO;
	[_passcodeTextField becomeFirstResponder];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[BWAnalytics sharedInstance] trackViewNamed:kViewNamePasscodeView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!_displayedAsModal && !_displayedAsLockScreen) {
        [_passcodeTextField resignFirstResponder];
    }
}


- (void)_cancelAndDismissMe {
	_isCurrentlyOnScreen = NO;
	_isUserBeingAskedForNewPasscode = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
	_isUserTurningPasscodeOff = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
	[self _resetUI];
	[_passcodeTextField resignFirstResponder];
	
    if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWillClose)]) {
		[self.delegate performSelector: @selector(passcodeViewControllerWillClose)];
    }
	else if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWasDismissed)]) {
		[self.delegate performSelector: @selector(passcodeViewControllerWasDismissed)];
    }
// Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"dismissPasscodeViewController"
//														object: self
//													  userInfo: nil];
	if (_displayedAsModal) [self dismissViewControllerAnimated:YES completion:nil];
	else if (!_displayedAsLockScreen) [self.navigationController popViewControllerAnimated:YES];
}


- (void)_dismissMe {
	_isCurrentlyOnScreen = NO;
	[self _resetUI];
	[_passcodeTextField resignFirstResponder];
	[UIView animateWithDuration: _lockAnimationDuration animations: ^{
		if (_displayedAsLockScreen) {
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
				[self _deletePasscode];
			}
			// Update the Keychain if adding or changing passcode
			else {
				[self _savePasscode:_tempPasscode];
                //finalize type switching
                if (_isUserSwitchingBetweenPasscodeModes) {
                    _isUserConfirmingPasscode = NO;
                    [self setIsSimple:!self.isSimple
                     inViewController:nil
                              asModal:_displayedAsModal];
                }
			}
		}
	} completion: ^(BOOL finished) {
        if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWillClose)]) {
            [self.delegate performSelector: @selector(passcodeViewControllerWillClose)];
        }
        else if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWasDismissed)]) {
			[self.delegate performSelector: @selector(passcodeViewControllerWasDismissed)];
        }
// Or, if you prefer by notifications:
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"dismissPasscodeViewController"
//															object: self
//														  userInfo: nil];
		if (_displayedAsLockScreen) {
			[self.view removeFromSuperview];
			[self removeFromParentViewController];
		}
        else if (_displayedAsModal) {
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        }
        else if (!_displayedAsLockScreen) {
            [self.navigationController popViewControllerAnimated:NO];
        }
	}];
	[[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: UIApplicationDidChangeStatusBarOrientationNotification
     object: nil];
	[[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: UIApplicationDidChangeStatusBarFrameNotification
     object: nil];
}


#pragma mark - UI setup
- (void)_setupViews {
    _coverView = [[UIView alloc] initWithFrame: CGRectZero];
    _coverView.backgroundColor = _coverViewBackgroundColor;
    _coverView.frame = self.view.frame;
    _coverView.userInteractionEnabled = NO;
    _coverView.tag = _coverViewTag;
    _coverView.hidden = YES;
    [[UIApplication sharedApplication].keyWindow addSubview: _coverView];
    
    _complexPasscodeOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
    _complexPasscodeOverlayView.backgroundColor = [UIColor whiteColor];
    _complexPasscodeOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [_animatingView addSubview:_complexPasscodeOverlayView];
}


- (void)_setupLabels {
    _enterPasscodeLabel = [[UILabel alloc] initWithFrame: CGRectZero];
	_enterPasscodeLabel.backgroundColor = _enterPasscodeLabelBackgroundColor;
	_enterPasscodeLabel.numberOfLines = 0;
	_enterPasscodeLabel.textColor = _labelTextColor;
	_enterPasscodeLabel.font = _labelFont;
	_enterPasscodeLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _enterPasscodeLabel];
	
	// It is also used to display the "Passcodes did not match" error message
    // if the user fails to confirm the passcode.
	_failedAttemptLabel = [[UILabel alloc] initWithFrame: CGRectZero];
	_failedAttemptLabel.text = @"1 Passcode Failed Attempt";
    _failedAttemptLabel.numberOfLines = 0;
	_failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
	_failedAttemptLabel.hidden = YES;
	_failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
	_failedAttemptLabel.font = _failedAttemptLabelFont;
	_failedAttemptLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _failedAttemptLabel];

    _forgottenPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_forgottenPasswordButton addTarget:self action:@selector(handleForgottenPasswordTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_forgottenPasswordButton setTitleColor:[Appearance limeThemeColor] forState:UIControlStateNormal];
    _forgottenPasswordButton.titleLabel.font = [UIFont bw_lightItalicMrEavesFontWithSize:22.f];
    [_animatingView addSubview:_forgottenPasswordButton];
    
    _enterPasscodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_failedAttemptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _forgottenPasswordButton.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self _resetUI];
}


- (void)_setupDigitFields {
    _firstDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _firstDigitTextField.backgroundColor = _passcodeBackgroundColor;
    _firstDigitTextField.textAlignment = NSTextAlignmentCenter;
    _firstDigitTextField.text = _passcodeCharacter;
    _firstDigitTextField.textColor = _passcodeTextColor;
    _firstDigitTextField.font = _passcodeFont;
    _firstDigitTextField.secureTextEntry = NO;
    [_firstDigitTextField setBorderStyle:UITextBorderStyleNone];
    _firstDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_firstDigitTextField];
    
    _secondDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _secondDigitTextField.backgroundColor = _passcodeBackgroundColor;
    _secondDigitTextField.textAlignment = NSTextAlignmentCenter;
    _secondDigitTextField.text = _passcodeCharacter;
    _secondDigitTextField.textColor = _passcodeTextColor;
    _secondDigitTextField.font = _passcodeFont;
    _secondDigitTextField.secureTextEntry = NO;
    [_secondDigitTextField setBorderStyle:UITextBorderStyleNone];
    _secondDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_secondDigitTextField];
    
    _thirdDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _thirdDigitTextField.backgroundColor = _passcodeBackgroundColor;
    _thirdDigitTextField.textAlignment = NSTextAlignmentCenter;
    _thirdDigitTextField.text = _passcodeCharacter;
    _thirdDigitTextField.textColor = _passcodeTextColor;
    _thirdDigitTextField.font = _passcodeFont;
    _thirdDigitTextField.secureTextEntry = NO;
    [_thirdDigitTextField setBorderStyle:UITextBorderStyleNone];
    _thirdDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_thirdDigitTextField];
    
    _fourthDigitTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _fourthDigitTextField.backgroundColor = _passcodeBackgroundColor;
    _fourthDigitTextField.textAlignment = NSTextAlignmentCenter;
    _fourthDigitTextField.text = _passcodeCharacter;
    _fourthDigitTextField.textColor = _passcodeTextColor;
    _fourthDigitTextField.font = _passcodeFont;
    _fourthDigitTextField.secureTextEntry = NO;
    [_fourthDigitTextField setBorderStyle:UITextBorderStyleNone];
    _fourthDigitTextField.userInteractionEnabled = NO;
    [_animatingView addSubview:_fourthDigitTextField];
    
    _firstDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _secondDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _thirdDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _fourthDigitTextField.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    _firstDigitTextField.hidden = !self.isSimple;
    _secondDigitTextField.hidden = !self.isSimple;
    _thirdDigitTextField.hidden = !self.isSimple;
    _fourthDigitTextField.hidden = !self.isSimple;
    
    _complexPasscodeOverlayView.hidden = self.isSimple;
    _passcodeTextField.hidden = self.isSimple;
	_passcodeTextField.keyboardType =
    self.isSimple ? UIKeyboardTypeNumberPad : UIKeyboardTypeASCIICapable;
    [_passcodeTextField reloadInputViews];
    
    if (self.isSimple) {
        [_animatingView addSubview:_passcodeTextField];
    }
    else {
        [_complexPasscodeOverlayView addSubview:_passcodeTextField];
        
        // If we come from simple state some constraints are added even if
        // translatesAutoresizingMaskIntoConstraints = NO,
        // because no constraints are added manually in that case
        [_passcodeTextField removeConstraints:_passcodeTextField.constraints];
    }
    
    // MARK: Please read
	// The controller works properly on all devices and orientations, but looks odd on iPhone's landscape.
	// Usually, lockscreens on iPhone are kept portrait-only, though. It also doesn't fit inside a modal when landscape.
	// That's why only portrait is selected for iPhone's supported orientations.
	// Modify this to fit your needs.
	
	
	CGFloat verticalGap = is4InchDeviceOrHigher() ? kVerticalGap4Inch : self.displayedAsLockScreen ? kVerticalGap35Inch : kVerticalGap35Inch + 15.0f;
	CGFloat topSpacing = is4InchDeviceOrHigher() ? kTopSpacing4Inch : self.displayedAsLockScreen ? kTopSpacing35Inch : kTopSpacing35Inch + 30.0f;
	
	NSLayoutConstraint *enterPasscodeConstraintCenterX =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
	NSLayoutConstraint *enterPasscodeConstraintCenterY =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeTop
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeTop
                                multiplier: 1.0f
                                  constant: topSpacing];
    [self.view addConstraint: enterPasscodeConstraintCenterX];
    [self.view addConstraint: enterPasscodeConstraintCenterY];
		
    if (self.isSimple) {
        NSLayoutConstraint *firstDigitX =
        [NSLayoutConstraint constraintWithItem: _firstDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.view
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: - kDigitHorizontalGap * 1.5f - 2.0f];
        NSLayoutConstraint *secondDigitX =
        [NSLayoutConstraint constraintWithItem: _secondDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.view
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: - kDigitHorizontalGap * 2/3 - 2.0f];
        NSLayoutConstraint *thirdDigitX =
        [NSLayoutConstraint constraintWithItem: _thirdDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.view
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: kDigitHorizontalGap * 1/6 - 2.0f];
        NSLayoutConstraint *fourthDigitX =
        [NSLayoutConstraint constraintWithItem: _fourthDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: self.view
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: kDigitHorizontalGap - 2.0f];
        NSLayoutConstraint *firstDigitY =
        [NSLayoutConstraint constraintWithItem: _firstDigitTextField
                                     attribute: NSLayoutAttributeTop
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: verticalGap];
        NSLayoutConstraint *secondDigitY =
        [NSLayoutConstraint constraintWithItem: _secondDigitTextField
                                     attribute: NSLayoutAttributeTop
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: verticalGap];
        NSLayoutConstraint *thirdDigitY =
        [NSLayoutConstraint constraintWithItem: _thirdDigitTextField
                                     attribute: NSLayoutAttributeTop
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: verticalGap];
        NSLayoutConstraint *fourthDigitY =
        [NSLayoutConstraint constraintWithItem: _fourthDigitTextField
                                     attribute: NSLayoutAttributeTop
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: verticalGap];
        [self.view addConstraint:firstDigitX];
        [self.view addConstraint:secondDigitX];
        [self.view addConstraint:thirdDigitX];
        [self.view addConstraint:fourthDigitX];
        [self.view addConstraint:firstDigitY];
        [self.view addConstraint:secondDigitY];
        [self.view addConstraint:thirdDigitY];
        [self.view addConstraint:fourthDigitY];
    }
	
    NSLayoutConstraint *failedAttemptLabelCenterX =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
	NSLayoutConstraint *failedAttemptLabelCenterY =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeBottom
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeBottom
                                multiplier: 1.0f
                                  constant: kFailedAttemptLabelYOffset];
	NSLayoutConstraint *failedAttemptLabelWidth =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeWidth
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeWidth
                                multiplier: 1.0f
                                  constant: 0.0f];
	NSLayoutConstraint *failedAttemptLabelHeight =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
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

    NSLayoutConstraint *forgottenPasswordButtonX =
    [NSLayoutConstraint constraintWithItem:_forgottenPasswordButton
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.view
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.f
                                  constant:0.f];
    NSLayoutConstraint *forgottenPasswordButtonY =
    [NSLayoutConstraint constraintWithItem:_forgottenPasswordButton
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_failedAttemptLabel
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.f
                                  constant:-10.f];
    NSLayoutConstraint *forgottenPasswordButtonWidth =
    [NSLayoutConstraint constraintWithItem:_forgottenPasswordButton
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.view
                                 attribute:NSLayoutAttributeWidth
                                multiplier:1.f
                                  constant:0.f];

    [self.view addConstraints:@[
                                forgottenPasswordButtonX,
                                forgottenPasswordButtonY,
                                forgottenPasswordButtonWidth,
                                ]];
    
}


#pragma mark - Displaying
- (void)showLockScreenWithAnimation:(BOOL)animated {
	[self.navBar removeFromSuperview];
	self.navBar = nil;
	[self showLockScreenWithAnimation:animated withLogout:NO andLogoutTitle:nil];
}


- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle {
	[self _prepareAsLockScreen];
	// In case the user leaves the app while the lockscreen is already active.
	if (!_isCurrentlyOnScreen) {
		// Usually, the app's window is the first on the stack. I'm doing this because if an alertView or actionSheet
		// is open when presenting the lockscreen causes problems, because the av/as has it's own window that replaces the keyWindow
		// and due to how Apple handles said window internally.
		// Currently the lockscreen appears behind the av/as, which is the best compromise for now.
		// You can read and/or give a hand following one of the links below
		// http://stackoverflow.com/questions/19816142/uialertviews-uiactionsheets-and-keywindow-problems
		// https://github.com/rolandleth/LTHPasscodeViewController/issues/16
		// Usually not more than one window is needed, but your needs may vary; modify below.
		// Also, in case the control doesn't work properly,
		// try it with .keyWindow before anything else, it might work.
		UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
//		UIWindow *mainWindow = [UIApplication sharedApplication].windows[0];
		[mainWindow addSubview: self.view];
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
									mainWindow.center.y - self.navigationController.navigationBar.frame.size.height / 2 + 22.0f);
		}
		else {
			self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
			newCenter = CGPointMake(mainWindow.center.x,
									mainWindow.center.y + self.navigationController.navigationBar.frame.size.height / 2);
		}
        
		if (animated) {
			[UIView animateWithDuration: _lockAnimationDuration animations: ^{
				self.view.center = newCenter;
			}];
		}
        else {
			self.view.center = newCenter;
		}
		
		// Add nav bar & logout button if specified
		if (hasLogout) {
			// Navigation Bar with custom UI
			self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, mainWindow.frame.origin.y, 320, 64)];
            self.navBar.tintColor = self.navigationTintColor;
			if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
				self.navBar.barTintColor = self.navigationBarTintColor;
				self.navBar.translucent  = self.navigationBarTranslucent;
			}
			if (self.navigationTitleColor) {
				self.navBar.titleTextAttributes =
				@{ NSForegroundColorAttributeName : self.navigationTitleColor };
			}
			
			// Navigation item
			UIBarButtonItem *leftButton =
            [[UIBarButtonItem alloc] initWithTitle:logoutTitle
                                             style:UIBarButtonItemStyleDone
                                            target:self
                                            action:@selector(_logoutWasPressed)];
			UINavigationItem *item =
            [[UINavigationItem alloc] initWithTitle:self.title];
			item.leftBarButtonItem = leftButton;
			item.hidesBackButton = YES;
			
			[self.navBar pushNavigationItem:item animated:NO];
			[mainWindow addSubview:self.navBar];
		}
		
		_isCurrentlyOnScreen = YES;
	}
}


- (void)_prepareNavigationControllerWithController:(UIViewController *)viewController {
	
	if (!_displayedAsModal) {
		[viewController.navigationController pushViewController:self
													   animated:YES];
        self.navigationItem.hidesBackButton = _hidesBackButton;
		return;
	}
	
	self.navigationItem.rightBarButtonItem =
	[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
												  target:self
												  action:@selector(_cancelAndDismissMe)];
	
	UINavigationController *navController =
	[[UINavigationController alloc] initWithRootViewController:self];
	
	// Make sure nav bar for logout is off the screen
	[self.navBar removeFromSuperview];
	self.navBar = nil;
	
	// Customize navigation bar
	// Make sure UITextAttributeTextColor is not set to nil
	// barTintColor & translucent is only called on iOS7+
	navController.navigationBar.tintColor = self.navigationTintColor;
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		navController.navigationBar.barTintColor = self.navigationBarTintColor;
		navController.navigationBar.translucent = self.navigationBarTranslucent;
	}
	if (self.navigationTitleColor) {
		navController.navigationBar.titleTextAttributes =
		@{ NSForegroundColorAttributeName : self.navigationTitleColor };
	}
	
	[viewController presentViewController:navController
								 animated:YES
							   completion:nil];
	[self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}


- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController {
	[self showForEnablingPasscodeInViewController:viewController
										  asModal:YES];
}


- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController {
	[self showForChangingPasscodeInViewController:viewController
										  asModal:YES];
}


- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController {
	[self showForDisablingPasscodeInViewController:viewController
                                           asModal:YES];
}


- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController
										asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForEnablingPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = LocalizedString(@"PASSCODE_ENABLE_PASSCODE");
}


- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController
										asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForChangingPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = LocalizedString(@"PASSCODE_CHANGE_PASSCODE");
}


- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController
                                         asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForTurningOffPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = LocalizedString(@"PASSCODE_DISABLE_PASSCODE");
}


#pragma mark - Preparing
- (void)_prepareAsLockScreen {
    // In case the user leaves the app while changing/disabling Passcode.
    if (_isCurrentlyOnScreen && !_displayedAsLockScreen) {
        [self _cancelAndDismissMe];
    }
    _displayedAsLockScreen = YES;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
    
	[self _resetUI];
}


- (void)_prepareForChangingPasscode {
	_isCurrentlyOnScreen = YES;
	_displayedAsLockScreen = NO;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
    
	[self _resetUI];
}


- (void)_prepareForTurningOffPasscode {
	_isCurrentlyOnScreen = YES;
	_displayedAsLockScreen = NO;
	_isUserTurningPasscodeOff = YES;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
    
	[self _resetUI];
}


- (void)_prepareForEnablingPasscode {
	_isCurrentlyOnScreen = YES;
	_displayedAsLockScreen = NO;
	_isUserTurningPasscodeOff = NO;
	_isUserChangingPasscode = NO;
	_isUserConfirmingPasscode = NO;
	_isUserEnablingPasscode = YES;
    _isUserSwitchingBetweenPasscodeModes = NO;
    
	[self _resetUI];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (!_displayedAsLockScreen && !_displayedAsModal) return YES;
	return !_isCurrentlyOnScreen;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if ([string isEqualToString: @"\n"]) return NO;
    
    NSString *typedString = [textField.text stringByReplacingCharactersInRange: range
                                                                    withString: string];
    
    if (self.isSimple) {
        if (typedString.length >= 1) _firstDigitTextField.secureTextEntry = YES;
        else _firstDigitTextField.secureTextEntry = NO;
        if (typedString.length >= 2) _secondDigitTextField.secureTextEntry = YES;
        else _secondDigitTextField.secureTextEntry = NO;
        if (typedString.length >= 3) _thirdDigitTextField.secureTextEntry = YES;
        else _thirdDigitTextField.secureTextEntry = NO;
        if (typedString.length >= 4) _fourthDigitTextField.secureTextEntry = YES;
        else _fourthDigitTextField.secureTextEntry = NO;
        
        if (typedString.length == 4) {
        	// Make the last bullet show up
			[self performSelector: @selector(_validatePasscode:)
					   withObject: typedString
					   afterDelay: 0.15];
		}
        
        if (typedString.length > 4) return NO;
    }
	
	return YES;
}

#pragma mark - Validation
- (void)_validateComplexPasscode {
    NSLog(@"isValid %@", [self _validatePasscode:_passcodeTextField.text] ? @"YES" : @"NO");
}


- (BOOL)_validatePasscode:(NSString *)typedString {
    NSString *savedPasscode = [self _passcode];
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
            [self performSelector:@selector(_askForConfirmationPasscode)
                       withObject:nil
                       afterDelay:0.15f];
        }
        // User entered his Passcode correctly and we are at the confirming screen.
        else if (_isUserConfirmingPasscode) {
            // User entered the confirmation Passcode correctly
            if ([typedString isEqualToString: _tempPasscode]) {
                [self _dismissMe];
            }
            // User entered the confirmation Passcode incorrectly, start over.
            else {
                [self performSelector:@selector(_reAskForNewPasscode)
                           withObject:nil
                           afterDelay:_slideAnimationDuration];
            }
        }
        // Changing Passcode and the entered Passcode is correct.
        else if ([typedString isEqualToString:savedPasscode]){
            [self performSelector:@selector(_askForNewPasscode)
                       withObject:nil
                       afterDelay:_slideAnimationDuration];
            _failedAttempts = 0;
        }
        // Acting as lockscreen and the entered Passcode is incorrect.
        else {
            [self performSelector: @selector(_denyAccess)
                       withObject: nil
                       afterDelay: _slideAnimationDuration];
            return NO;
        }
    }
    // App launch/Turning passcode off: Passcode OK -> dismiss, Passcode incorrect -> deny access.
    else {
        if ([typedString isEqualToString: savedPasscode]) {
            if ([self.delegate respondsToSelector: @selector(passcodeWasEnteredSuccessfully)]) {
                [self.delegate performSelector: @selector(passcodeWasEnteredSuccessfully)];
            }
//Or, if you prefer by notifications:
//            [[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeWasEnteredSuccessfully"
//                                                                object: self
//                                                              userInfo: nil];
            [self _dismissMe];
        }
        else {
            [self performSelector: @selector(_denyAccess)
                       withObject: nil
                       afterDelay: _slideAnimationDuration];
            return NO;
        }
    }
    
    return YES;
}


#pragma mark - Actions
- (void)_askForNewPasscode {
	_isUserBeingAskedForNewPasscode = YES;
	_isUserConfirmingPasscode = NO;
    
    // Update layout considering type
    [self.view setNeedsUpdateConstraints];
    
	_failedAttemptLabel.hidden = YES;
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(_resetUI) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: _slideAnimationDuration];
	[transition setTimingFunction:
     [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)_reAskForNewPasscode {
	_isUserBeingAskedForNewPasscode = YES;
	_isUserConfirmingPasscode = NO;
	_tempPasscode = @"";
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(_resetUIForReEnteringNewPasscode)
               withObject: nil
               afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: _slideAnimationDuration];
	[transition setTimingFunction:
     [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)_askForConfirmationPasscode {
	_isUserBeingAskedForNewPasscode = NO;
	_isUserConfirmingPasscode = YES;
	_failedAttemptLabel.hidden = YES;
	
	CATransition *transition = [CATransition animation];
	[transition setDelegate: self];
	[self performSelector: @selector(_resetUI) withObject: nil afterDelay: 0.1f];
	[transition setType: kCATransitionPush];
	[transition setSubtype: kCATransitionFromRight];
	[transition setDuration: _slideAnimationDuration];
	[transition setTimingFunction:
     [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut]];
	[[_animatingView layer] addAnimation: transition forKey: @"swipe"];
}


- (void)_denyAccess {
	[self _resetTextFields];
	_passcodeTextField.text = @"";
    
	_failedAttempts++;
	
	if (_maxNumberOfAllowedFailedAttempts > 0 &&
		_failedAttempts == _maxNumberOfAllowedFailedAttempts &&
		[self.delegate respondsToSelector: @selector(maxNumberOfFailedAttemptsReached)]) {
		[self.delegate maxNumberOfFailedAttemptsReached];
    }
//	Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"maxNumberOfFailedAttemptsReached"
//														object: self
//													  userInfo: nil];
	
	if (_failedAttempts == 1) {
        _failedAttemptLabel.text = LocalizedString(@"PASSCODE_1_FAILED_ATTEMPT");
    }
	else {
		_failedAttemptLabel.text = [NSString stringWithFormat:LocalizedString(@"PASSCODE_N_FAILED_ATTEMPTS"), _failedAttempts];
	}
	_failedAttemptLabel.hidden = NO;
}


- (void)_logoutWasPressed {
	// Notify delegate that logout button was pressed
	if ([self.delegate respondsToSelector: @selector(logoutButtonWasPressed)]) {
		[self.delegate logoutButtonWasPressed];
	}
}


- (void)_resetTextFields {
	if (![_passcodeTextField isFirstResponder]) [_passcodeTextField becomeFirstResponder];
	_firstDigitTextField.secureTextEntry = NO;
	_secondDigitTextField.secureTextEntry = NO;
	_thirdDigitTextField.secureTextEntry = NO;
	_fourthDigitTextField.secureTextEntry = NO;
}

- (void)setLabelText {
	
	if (_isUserChangingPasscode) {
		if (_isUserBeingAskedForNewPasscode) {
			_enterPasscodeLabel.text = LocalizedString(@"PASSCODE_ENTER_YOUR_NEW_PASSCODE");
		}
		else if (_isUserConfirmingPasscode) {
			_enterPasscodeLabel.text = LocalizedString(@"PASSCODE_RE-ENTER_YOUR_NEW_PASSCODE");
		}
		else {
			_enterPasscodeLabel.text = LocalizedString(@"PASSCODE_ENTER_YOUR_OLD_PASSCODE");
		}
	}
	else if (_isUserEnablingPasscode) {
		if (_isUserConfirmingPasscode) {
			_enterPasscodeLabel.text = LocalizedString(@"PASSCODE_RE-ENTER_YOUR_NEW_PASSCODE");
		}
		else {
			_enterPasscodeLabel.text = LocalizedString(@"PASSCODE_ENTER_YOUR_NEW_PASSCODE");
		}
	}
	else {
		_enterPasscodeLabel.text = LocalizedString(@"PASSCODE_ENTER_YOUR_PASSCODE");
	}

    [_forgottenPasswordButton setTitle:LocalizedString(@"PASSCODE_FORGOTTEN_PASSWORD") forState:UIControlStateNormal];
}

- (void)_resetUI {
	[self _resetTextFields];
	_failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
	_failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
	_failedAttempts = 0;
	_failedAttemptLabel.hidden = YES;
	_passcodeTextField.text = @"";

    _forgottenPasswordButton.hidden = !_displayedAsLockScreen;
	
	[self setLabelText];
	
	// Make sure nav bar for logout is off the screen
	[self.navBar removeFromSuperview];
	self.navBar = nil;
    
}

- (void)_resetUIForReEnteringNewPasscode {
	[self _resetTextFields];
	_passcodeTextField.text = @"";
	// If there's no passcode saved in Keychain,
    // the user is adding one for the first time, otherwise he's changing his passcode.
	NSString *savedPasscode = [SFHFKeychainUtils getPasswordForUsername: _keychainPasscodeUsername
														 andServiceName: _keychainServiceName
																  error: nil];
	_enterPasscodeLabel.text = savedPasscode.length == 0 ? LocalizedString(@"PASSCODE_ENTER_YOUR_PASSCODE") : LocalizedString(@"PASSCODE_ENTER_YOUR_NEW_PASSCODE");
	
	_failedAttemptLabel.hidden = NO;
	_failedAttemptLabel.text = LocalizedString(@"PASSCODE_DID_NOT_MATCH");
	_failedAttemptLabel.backgroundColor = _failedAttemptLabelBackgroundColor;
	_failedAttemptLabel.layer.borderWidth = 0;
	_failedAttemptLabel.layer.borderColor = [UIColor clearColor].CGColor;
	_failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
}


- (void)setIsSimple:(BOOL)isSimple inViewController:(UIViewController *)viewController asModal:(BOOL)isModal{
    if (!_isUserSwitchingBetweenPasscodeModes &&
        !_isUserBeingAskedForNewPasscode &&
        [self _doesPasscodeExist]) {
        // User trying to change passcode type while having passcode already
        _isUserSwitchingBetweenPasscodeModes = YES;
        // Display modified change passcode flow starting with input once passcode
        // of current type and then 2 times new one of another type
        [self showForChangingPasscodeInViewController:viewController
                                              asModal:isModal];
    }
    else {
        _isUserSwitchingBetweenPasscodeModes = NO;
        _isSimple = isSimple;
        [self.view setNeedsUpdateConstraints];
    }
}

- (BOOL)isSimple {
    // Is in process of changing, but not finished ->
    // we need to display UI accordingly
    if (_isUserSwitchingBetweenPasscodeModes && (_isUserBeingAskedForNewPasscode || _isUserConfirmingPasscode)) {
        return !_isSimple;
    }
    
    return _isSimple;
}

#pragma mark - Action actions, geez

- (IBAction)handleForgottenPasswordTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(iWishIRememberedMyPasscode)]) {
        [self.delegate iWishIRememberedMyPasscode];
    }
}

#pragma mark - Init
+ (instancetype)sharedUser {
    __strong static LTHPasscodeViewController *sharedObject = nil;
    
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedObject = [[LTHPasscodeViewController alloc] init];
	});
	
	return sharedObject;
}


- (id)init {
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _commonInit];
    }
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _commonInit];
    }
    return self;
}


- (void)_commonInit {
	_isSimple = YES;
	[self _loadDefaults];
	[self _addObservers];
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		[self setEdgesForExtendedLayout:UIRectEdgeAll];
	}
}


- (void)_loadDefaults {
    _coverViewTag = 994499;
    _lockAnimationDuration = 0.25;
    _slideAnimationDuration = 0.15f;
    _maxNumberOfAllowedFailedAttempts = 0;
    _usesKeychain = YES;
    _displayedAsModal = YES;
    _hidesBackButton = NO;
        
    // Fonts
    _labelFontSize = 44.0;
	_failedAttemptLabelFontSize = 16.0f;
    _passcodeFontSize = 33.0;
    _labelFont = [UIFont bw_lightMrEavesFontWithSize:_labelFontSize];
	_failedAttemptLabelFont = [UIFont bw_regularMrEavesFontWithSize:_failedAttemptLabelFontSize];
    _passcodeFont = [UIFont bw_lightMrEavesFontWithSize:_labelFontSize];
    
    // Colors
    _backgroundColor =  [Appearance backgroundColor];
    _passcodeBackgroundColor = [UIColor clearColor];
    _coverViewBackgroundColor = [Appearance backgroundColor];
    _failedAttemptLabelBackgroundColor =  [Appearance redThemeColor];
    _enterPasscodeLabelBackgroundColor = [UIColor clearColor];
    
    // Text Colors
    _labelTextColor = [Appearance redThemeColor];
    _passcodeTextColor = [UIColor colorWithWhite:0.31f alpha:1.0f];
    _failedAttemptLabelTextColor = [Appearance backgroundColor];
    
    // Keychain & misc
    _keychainPasscodeUsername = @"cluePasscode";
    _keychainTimerStartUsername = @"cluePasscodeTimerStart";
    _keychainServiceName = @"clueServiceName";
    _keychainTimerDurationUsername = @"passcodeTimerDuration";
    _passcodeCharacter = @"\u2014"; // A longer "-";
}


- (void)_addObservers {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(statusBarFrameOrOrientationChanged:)
     name:UIApplicationDidChangeStatusBarOrientationNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(statusBarFrameOrOrientationChanged:)
     name:UIApplicationDidChangeStatusBarFrameNotification
     object:nil];
}


#pragma mark - Handling rotation
- (NSUInteger)supportedInterfaceOrientations {
	if (_displayedAsLockScreen) return UIInterfaceOrientationMaskAll;
	// I'll be honest and mention I have no idea why this line of code below works.
	// Without it, if you present the passcode view as lockscreen (directly on the window)
	// and then inside of a modal, the orientation will be wrong.
	
	// If you could explain why, I'd be more than grateful :)
	return UIInterfaceOrientationPortraitUpsideDown;
}


// All of the rotation handling is thanks to Håvard Fossli's - https://github.com/hfossli
// answer: http://stackoverflow.com/a/4960988/793916
- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification {
    /*
     This notification is most likely triggered inside an animation block,
     therefore no animation is needed to perform this nice transition.
     */
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}


// And to his AGWindowView: https://github.com/hfossli/AGWindowView
// Without the 'desiredOrientation' method, using showLockscreen in one orientation,
// then presenting it inside a modal in another orientation would display
// the view in the first orientation.
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
            angle = (float)M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -(float)M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = (float)M_PI_2;
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

# pragma mark - Custom added methods

- (void)addClueLogo {
	
	UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passcode_logo"]];
	
	CGRect frame = iv.frame;
	frame.origin.x = 160.0f - frame.size.width/2;
	frame.origin.y = 30.0f;
	iv.frame = frame;
	[self.view addSubview:iv];
}

@end
