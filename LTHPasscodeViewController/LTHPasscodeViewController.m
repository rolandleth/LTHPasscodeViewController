//
//  PasscodeViewController.m
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHPasscodeViewController.h"
#import "LTHKeychainUtils.h"
#if !(TARGET_IPHONE_SIMULATOR)
#import <LocalAuthentication/LocalAuthentication.h>
#endif

#define DegreesToRadians(x) ((x) * M_PI / 180.0)
#define LTHiOS8 ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" \
options:NSNumericSearch] != NSOrderedAscending)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define kPasscodeCharWidth [_passcodeCharacter sizeWithAttributes: @{NSFontAttributeName : _passcodeFont}].width
#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width + 60.0f : [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width + 30.0f)
#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].height
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].width
#else
// Thanks to Kent Nguyen - https://github.com/kentnguyen
#define kPasscodeCharWidth [_passcodeCharacter sizeWithFont:_passcodeFont].width
#define kFailedAttemptLabelWidth (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [_failedAttemptLabel.text sizeWithFont:_labelFont].width + 60.0f : [_failedAttemptLabel.text sizeWithFont:_labelFont].width + 20.0f)
#define kFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithFont:_labelFont].height
#define kEnterPasscodeLabelWidth [_enterPasscodeLabel.text sizeWithFont:_labelFont].width
#endif

#ifndef LTHPasscodeViewControllerStrings
#define LTHPasscodeViewControllerStrings(key) \
[[NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"LTHPasscodeViewController" ofType:@"bundle"]] localizedStringForKey:(key) value:@"" table:_localizationTableName]
#endif

@interface LTHPasscodeViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIView      *coverView;
@property (nonatomic, strong) UIView      *animatingView;
@property (nonatomic, strong) UIView      *complexPasscodeOverlayView;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@property (nonatomic, strong) UITextField *passcodeTextField;
@property (nonatomic, strong) UITextField *firstDigitTextField;
@property (nonatomic, strong) UITextField *secondDigitTextField;
@property (nonatomic, strong) UITextField *thirdDigitTextField;
@property (nonatomic, strong) UITextField *fourthDigitTextField;

@property (nonatomic, strong) UILabel     *failedAttemptLabel;
@property (nonatomic, strong) UILabel     *enterPasscodeLabel;
@property (nonatomic, strong) UIButton    *OKButton;

@property (nonatomic, strong) NSString    *tempPasscode;
@property (nonatomic, assign) NSInteger   failedAttempts;

@property (nonatomic, assign) CGFloat     modifierForBottomVerticalGap;
@property (nonatomic, assign) CGFloat     iPadFontSizeModifier;
@property (nonatomic, assign) CGFloat     iPhoneHorizontalGap;

@property (nonatomic, assign) BOOL        usesKeychain;
@property (nonatomic, assign) BOOL        displayedAsModal;
@property (nonatomic, assign) BOOL        displayedAsLockScreen;
@property (nonatomic, assign) BOOL        isUsingNavbar;
@property (nonatomic, assign) BOOL        isCurrentlyOnScreen;
@property (nonatomic, assign) BOOL        isSimple;// YES by default
@property (nonatomic, assign) BOOL        isUserConfirmingPasscode;
@property (nonatomic, assign) BOOL        isUserBeingAskedForNewPasscode;
@property (nonatomic, assign) BOOL        isUserTurningPasscodeOff;
@property (nonatomic, assign) BOOL        isUserChangingPasscode;
@property (nonatomic, assign) BOOL        isUserEnablingPasscode;
@property (nonatomic, assign) BOOL        isUserSwitchingBetweenPasscodeModes;// simple/complex
@property (nonatomic, assign) BOOL        timerStartInSeconds;
@property (nonatomic, assign) BOOL        isUsingTouchID;
@property (nonatomic, assign) BOOL        useFallbackPasscode;
@property (nonatomic, assign) BOOL        isAppNotificationsObserved;

#if !(TARGET_IPHONE_SIMULATOR)
@property (nonatomic, strong) LAContext   *context;
#endif
@end

@implementation LTHPasscodeViewController


#pragma mark - Public, class methods
+ (BOOL)doesPasscodeExist {
	return [[self sharedUser] _doesPasscodeExist];
}


+ (NSString *)passcode {
	return [[self sharedUser] _passcode];
}


+ (NSTimeInterval)timerDuration {
	return [[self sharedUser] _timerDuration];
}


+ (void)saveTimerDuration:(NSTimeInterval)duration {
    [[self sharedUser] _saveTimerDuration:duration];
}


+ (NSTimeInterval)timerStartTime {
    return [[self sharedUser] _timerStartTime];
}


+ (void)saveTimerStartTime {
	[[self sharedUser] _saveTimerStartTime];
}


+ (BOOL)didPasscodeTimerEnd {
	return [[self sharedUser] _didPasscodeTimerEnd];
}


+ (void)deletePasscodeAndClose {
	[self deletePasscode];
    [self close];
}


+ (void)close {
    [[self sharedUser] _close];
}


+ (void)deletePasscode {
	[[self sharedUser] _deletePasscode];
}


+ (void)useKeychain:(BOOL)useKeychain {
    [[self sharedUser] _useKeychain:useKeychain];
}


#pragma mark - Private methods
- (void)_close {
    if (_displayedAsLockScreen) [self _dismissMe];
    else [self _cancelAndDismissMe];
}


- (void)_useKeychain:(BOOL)useKeychain {
    _usesKeychain = useKeychain;
}


- (BOOL)_doesPasscodeExist {
	return [self _passcode].length != 0;
}


- (NSTimeInterval)_timerDuration {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(timerDuration)]) {
        return [self.delegate timerDuration];
    }
    
	NSString *keychainValue =
    [LTHKeychainUtils getPasswordForUsername:_keychainTimerDurationUsername
                               andServiceName:_keychainServiceName
                                        error:nil];
	if (!keychainValue) return -1;
	return keychainValue.doubleValue;
}


- (void)_saveTimerDuration:(NSTimeInterval) duration {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(saveTimerDuration:)]) {
        [self.delegate saveTimerDuration:duration];
        
        return;
    }
    
    [LTHKeychainUtils storeUsername:_keychainTimerDurationUsername
						 andPassword:[NSString stringWithFormat: @"%.6f", duration]
					  forServiceName:_keychainServiceName
					  updateExisting:YES
							   error:nil];
}


- (NSTimeInterval)_timerStartTime {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(timerStartTime)]) {
        return [self.delegate timerStartTime];
    }
    
    NSString *keychainValue =
    [LTHKeychainUtils getPasswordForUsername:_keychainTimerStartUsername
                               andServiceName:_keychainServiceName
                                        error:nil];
	if (!keychainValue) return -1;
	return keychainValue.doubleValue;
}


- (void)_saveTimerStartTime {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(saveTimerStartTime)]) {
        [self.delegate saveTimerStartTime];
        
        return;
    }
    
	[LTHKeychainUtils storeUsername:_keychainTimerStartUsername
						 andPassword:[NSString stringWithFormat: @"%.6f",
                                      [NSDate timeIntervalSinceReferenceDate]]
					  forServiceName:_keychainServiceName
					  updateExisting:YES
							   error:nil];
}


- (BOOL)_didPasscodeTimerEnd {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(didPasscodeTimerEnd)]) {
        return [self.delegate didPasscodeTimerEnd];
    }
    
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	// startTime wasn't saved yet (first app use and it crashed, phone force
	// closed, etc) if it returns -1.
	if (now - [self _timerStartTime] >= [self _timerDuration] ||
        [self _timerStartTime] == -1) return YES;
	return NO;
}


- (void)_deletePasscode {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(deletePasscode)]) {
        [self.delegate deletePasscode];
        
        return;
    }
    
	[LTHKeychainUtils deleteItemForUsername:_keychainPasscodeUsername
							  andServiceName:_keychainServiceName
									   error:nil];
}


- (void)_savePasscode:(NSString *)passcode {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(savePasscode:)]) {
        [self.delegate savePasscode:passcode];
        
        return;
    }
    
    [LTHKeychainUtils storeUsername:_keychainPasscodeUsername
                         andPassword:passcode
                      forServiceName:_keychainServiceName
                      updateExisting:YES
                               error:nil];
    
    
    [LTHKeychainUtils storeUsername:_keychainPasscodeIsSimpleUsername
                        andPassword:[NSString stringWithFormat:@"%@", [self isSimple] ? @"YES" : @"NO"]
                     forServiceName:_keychainServiceName
                     updateExisting:YES
                              error:nil];
}


- (NSString *)_passcode {
	if (!_usesKeychain &&
		[self.delegate respondsToSelector:@selector(passcode)]) {
		return [self.delegate passcode];
	}
	
	return [LTHKeychainUtils getPasswordForUsername:_keychainPasscodeUsername
									  andServiceName:_keychainServiceName
											   error:nil];
}

#if !(TARGET_IPHONE_SIMULATOR)
- (void)_setupFingerPrint {
    if (!self.context && _allowUnlockWithTouchID) {
        self.context = [[LAContext alloc] init];
        
        NSError *error = nil;
        if ([self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            if (error) {
                return;
            }
            
            _isUsingTouchID = YES;
            [_passcodeTextField resignFirstResponder];
            _animatingView.hidden = YES;

            // Authenticate User
            [self.context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                         localizedReason:LTHPasscodeViewControllerStrings(self.touchIDString)
                                   reply:^(BOOL success, NSError *error) {
                                       
                                       if (error) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               _useFallbackPasscode = YES;
                                               _animatingView.hidden = NO;
                                               [self _resetUI];
                                           });
                                           self.context = nil;
                                           return;
                                       }
                                       
                                       if (success) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [self _dismissMe];
                                               
                                               if ([self.delegate respondsToSelector: @selector(passcodeWasEnteredSuccessfully)]) {
                                                   [self.delegate performSelector: @selector(passcodeWasEnteredSuccessfully)];
                                               }
                                           });
                                       }
                                       else {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               _useFallbackPasscode = YES;
                                               _animatingView.hidden = NO;
                                               [self _resetUI];
                                           });
                                       }
                                       
                                       self.context = nil;
                                       
                                   }];
        }
    }
}
#endif

#pragma mark - View life
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = _backgroundColor;
    
    _backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_backgroundImageView];
    _backgroundImageView.image = _backgroundImage;
    
	_failedAttempts = 0;
	_animatingView = [[UIView alloc] initWithFrame: self.view.frame];
	[self.view addSubview: _animatingView];
    
	[self _setupViews];
    [self _setupLabels];
    [self _setupDigitFields];
    [self _setupOKButton];
	
	_passcodeTextField = [[UITextField alloc] initWithFrame: CGRectZero];
	_passcodeTextField.delegate = self;
    _passcodeTextField.secureTextEntry = YES;
    _passcodeTextField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view setNeedsUpdateConstraints];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    if (!self.isAppNotificationsObserved) {
        [self _addObservers];
        self.isAppNotificationsObserved = YES;
    }
	
    _backgroundImageView.image = _backgroundImage;
    if (!_isUsingTouchID) {
        [_passcodeTextField becomeFirstResponder];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_passcodeTextField.isFirstResponder && (!_isUsingTouchID || _isUserChangingPasscode || _isUserBeingAskedForNewPasscode || _isUserConfirmingPasscode || _isUserEnablingPasscode || _isUserSwitchingBetweenPasscodeModes || _isUserTurningPasscodeOff)) {
        [_passcodeTextField becomeFirstResponder];
        _animatingView.hidden = NO;
    }
    if (_isUsingTouchID && !_isUserChangingPasscode && !_isUserBeingAskedForNewPasscode && !_isUserConfirmingPasscode && !_isUserEnablingPasscode && !_isUserSwitchingBetweenPasscodeModes && !_isUserTurningPasscodeOff) {
        [_passcodeTextField resignFirstResponder];
        _animatingView.hidden = _isUsingTouchID;
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!_displayedAsModal && !_displayedAsLockScreen) {
        [self textFieldShouldEndEditing:_passcodeTextField];
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
// Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeViewControllerWillClose"
//														object: self
//													  userInfo: nil];
	if (_displayedAsModal) [self dismissViewControllerAnimated:YES completion:nil];
	else if (!_displayedAsLockScreen) [self.navigationController popViewControllerAnimated:YES];
}


- (void)_dismissMe {
    _failedAttempts = 0;
	_isCurrentlyOnScreen = NO;
	[self _resetUI];
	[_passcodeTextField resignFirstResponder];
	[UIView animateWithDuration: _lockAnimationDuration animations: ^{
		if (_displayedAsLockScreen) {
            if (LTHiOS8) {
                self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
            }
            else {
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
// Or, if you prefer by notifications:
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeViewControllerWillClose"
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
	_failedAttemptLabel.font = _labelFont;
	_failedAttemptLabel.textAlignment = NSTextAlignmentCenter;
	[_animatingView addSubview: _failedAttemptLabel];
    
    _enterPasscodeLabel.text = _isUserChangingPasscode ? LTHPasscodeViewControllerStrings(self.enterOldPasscodeString) : LTHPasscodeViewControllerStrings(self.enterPasscodeString);
    _enterPasscodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_failedAttemptLabel.translatesAutoresizingMaskIntoConstraints = NO;
}


- (void)_setupDigitFields {
    _firstDigitTextField = [self _makeDigitField];
    [_animatingView addSubview:_firstDigitTextField];
    
    _secondDigitTextField = [self _makeDigitField];
    [_animatingView addSubview:_secondDigitTextField];
    
    _thirdDigitTextField = [self _makeDigitField];
    [_animatingView addSubview:_thirdDigitTextField];
    
    _fourthDigitTextField = [self _makeDigitField];
    [_animatingView addSubview:_fourthDigitTextField];
}


- (UITextField *)_makeDigitField{
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.backgroundColor = _passcodeBackgroundColor;
    field.textAlignment = NSTextAlignmentCenter;
    field.text = _passcodeCharacter;
    field.textColor = _passcodeTextColor;
    field.font = _passcodeFont;
    field.secureTextEntry = NO;
    field.userInteractionEnabled = NO;
    field.translatesAutoresizingMaskIntoConstraints = NO;
    [field setBorderStyle:UITextBorderStyleNone];
    return field;
}


- (void)_setupOKButton {
    _OKButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_OKButton setTitle:LTHPasscodeViewControllerStrings(@"OK")
               forState:UIControlStateNormal];
    _OKButton.titleLabel.font = _labelFont;
    _OKButton.backgroundColor = _enterPasscodeLabelBackgroundColor;
    [_OKButton setTitleColor:_labelTextColor forState:UIControlStateNormal];
    [_OKButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [_OKButton addTarget:self
                  action:@selector(_validateComplexPasscode)
        forControlEvents:UIControlEventTouchUpInside];
    [_complexPasscodeOverlayView addSubview:_OKButton];
    
    _OKButton.hidden = YES;
    _OKButton.translatesAutoresizingMaskIntoConstraints = NO;
}


- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.view removeConstraints:self.view.constraints];
    [_animatingView removeConstraints:_animatingView.constraints];
    
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
	
	CGFloat yOffsetFromCenter = -self.view.frame.size.height * 0.24 + _verticalOffset;
	NSLayoutConstraint *enterPasscodeConstraintCenterX =
	[NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
								 attribute: NSLayoutAttributeCenterX
								 relatedBy: NSLayoutRelationEqual
									toItem: _animatingView
								 attribute: NSLayoutAttributeCenterX
								multiplier: 1.0f
								  constant: 0.0f];
	NSLayoutConstraint *enterPasscodeConstraintCenterY =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeCenterY
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterY
                                multiplier: 1.0f
                                  constant: yOffsetFromCenter];
    [self.view addConstraint: enterPasscodeConstraintCenterX];
    [self.view addConstraint: enterPasscodeConstraintCenterY];
	
    if (self.isSimple) {
        NSLayoutConstraint *firstDigitX =
        [NSLayoutConstraint constraintWithItem: _firstDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: - _horizontalGap * 1.5f - 2.0f];
        NSLayoutConstraint *secondDigitX =
        [NSLayoutConstraint constraintWithItem: _secondDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: - _horizontalGap * 2/3 - 2.0f];
        NSLayoutConstraint *thirdDigitX =
        [NSLayoutConstraint constraintWithItem: _thirdDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: _horizontalGap * 1/6 - 2.0f];
        NSLayoutConstraint *fourthDigitX =
        [NSLayoutConstraint constraintWithItem: _fourthDigitTextField
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0f
                                      constant: _horizontalGap - 2.0f];
        NSLayoutConstraint *firstDigitY =
        [NSLayoutConstraint constraintWithItem: _firstDigitTextField
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: _verticalGap];
        NSLayoutConstraint *secondDigitY =
        [NSLayoutConstraint constraintWithItem: _secondDigitTextField
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: _verticalGap];
        NSLayoutConstraint *thirdDigitY =
        [NSLayoutConstraint constraintWithItem: _thirdDigitTextField
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: _verticalGap];
        NSLayoutConstraint *fourthDigitY =
        [NSLayoutConstraint constraintWithItem: _fourthDigitTextField
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: _verticalGap];
        [self.view addConstraint:firstDigitX];
        [self.view addConstraint:secondDigitX];
        [self.view addConstraint:thirdDigitX];
        [self.view addConstraint:fourthDigitX];
        [self.view addConstraint:firstDigitY];
        [self.view addConstraint:secondDigitY];
        [self.view addConstraint:thirdDigitY];
        [self.view addConstraint:fourthDigitY];
    }
    else {
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_passcodeTextField, _OKButton);
        
        //TODO: specify different offsets through metrics
        NSArray *constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_passcodeTextField]-5-[_OKButton]-10-|"
                                                options:0
                                                metrics:nil
                                                  views:viewsDictionary];
        
        [self.view addConstraints:constraints];
        
        constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_passcodeTextField]-5-|"
                                                options:0
                                                metrics:nil
                                                  views:viewsDictionary];
        
        [self.view addConstraints:constraints];
        
        NSLayoutConstraint *buttonY =
        [NSLayoutConstraint constraintWithItem: _OKButton
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _passcodeTextField
                                     attribute: NSLayoutAttributeCenterY
                                    multiplier: 1.0f
                                      constant: 0.0f];
        
        [self.view addConstraint:buttonY];
        
        NSLayoutConstraint *buttonHeight =
        [NSLayoutConstraint constraintWithItem: _OKButton
                                     attribute: NSLayoutAttributeHeight
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _passcodeTextField
                                     attribute: NSLayoutAttributeHeight
                                    multiplier: 1.0f
                                      constant: 0.0f];
        
        [self.view addConstraint:buttonHeight];
        
        NSLayoutConstraint *overlayViewLeftConstraint =
        [NSLayoutConstraint constraintWithItem: _complexPasscodeOverlayView
                                     attribute: NSLayoutAttributeLeft
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeLeft
                                    multiplier: 1.0f
                                      constant: 0.0f];
        
        NSLayoutConstraint *overlayViewY =
        [NSLayoutConstraint constraintWithItem: _complexPasscodeOverlayView
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0f
                                      constant: _verticalGap];
        
        NSLayoutConstraint *overlayViewHeight =
        [NSLayoutConstraint constraintWithItem: _complexPasscodeOverlayView
                                     attribute: NSLayoutAttributeHeight
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: nil
                                     attribute: NSLayoutAttributeNotAnAttribute
                                    multiplier: 1.0f
                                      constant: _passcodeOverlayHeight];
        
        NSLayoutConstraint *overlayViewWidth =
        [NSLayoutConstraint constraintWithItem: _complexPasscodeOverlayView
                                     attribute: NSLayoutAttributeWidth
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeWidth
                                    multiplier: 1.0f
                                      constant: 0.0f];
        [self.view addConstraints:@[overlayViewLeftConstraint, overlayViewY, overlayViewHeight, overlayViewWidth]];
    }
	
    NSLayoutConstraint *failedAttemptLabelCenterX =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
	NSLayoutConstraint *failedAttemptLabelCenterY =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeCenterY
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeBottom
                                multiplier: 1.0f
                                  constant: _failedAttemptLabelGap];
	NSLayoutConstraint *failedAttemptLabelWidth =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeWidth
                                 relatedBy: NSLayoutRelationGreaterThanOrEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 1.0f
                                  constant: kFailedAttemptLabelWidth];
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
    
//    NSLog(@"constraints %@", self.view.constraints);
//    NSLog(@"_passcodeTextField %@", _passcodeTextField.constraints);
}


#pragma mark - Displaying
- (void)showLockscreenWithoutAnimation {
	[self showLockScreenWithAnimation:NO withLogout:NO andLogoutTitle:nil];
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
//		UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
		UIWindow *mainWindow = [UIApplication sharedApplication].windows[0];
		[mainWindow addSubview: self.view];
//		[mainWindow.rootViewController addChildViewController: self];
		// All this hassle because a view added to UIWindow does not rotate automatically
		// and if we would have added the view anywhere else, it wouldn't display properly
		// (having a modal on screen when the user leaves the app, for example).
		[self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
		CGPoint newCenter;
        [self statusBarFrameOrOrientationChanged:nil];
        if (LTHiOS8) {
            self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
            newCenter = CGPointMake(mainWindow.center.x,
                                    mainWindow.center.y + self.navigationController.navigationBar.frame.size.height / 2);
        }
        else {
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
            _isUsingNavbar = hasLogout;
			// Navigation Bar with custom UI
			self.navBar =
			[[UINavigationBar alloc] initWithFrame:CGRectMake(0, mainWindow.frame.origin.y,
															  mainWindow.frame.size.width, 64)];
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
            [leftButton setTitlePositionAdjustment:UIOffsetMake(10, 0) forBarMetrics:UIBarMetricsDefault];
            
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
	if (!_hidesCancelButton) {
		self.navigationItem.rightBarButtonItem =
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													  target:self
													  action:@selector(_cancelAndDismissMe)];
	}
	
	if (!_displayedAsModal) {
		[viewController.navigationController pushViewController:self
													   animated:YES];
        self.navigationItem.hidesBackButton = _hidesBackButton;
        [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
        
		return;
	}
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


- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController
										asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForEnablingPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = LTHPasscodeViewControllerStrings(self.enablePasscodeString);
}


- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController
										asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForChangingPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = LTHPasscodeViewControllerStrings(self.changePasscodeString);
}


- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController
                                         asModal:(BOOL)isModal {
	_displayedAsModal = isModal;
	[self _prepareForTurningOffPasscode];
	[self _prepareNavigationControllerWithController:viewController];
	self.title = LTHPasscodeViewControllerStrings(self.turnOffPasscodeString);
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
    #if !(TARGET_IPHONE_SIMULATOR)
    [self _setupFingerPrint];
    #endif
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
    if ((!_displayedAsLockScreen && !_displayedAsModal) || (_isUsingTouchID || !_useFallbackPasscode)) {
        return YES;
    }
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
    else _OKButton.hidden = [typedString length] == 0;
	
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
// Or, if you prefer by notifications:
//            [[NSNotificationCenter defaultCenter] postNotificationName: @"passcodeWasEnteredSuccessfully"
//                                                                object: self
//                                                              userInfo: nil];
            [self _dismissMe];
            _useFallbackPasscode = NO;
            if ([self.delegate respondsToSelector: @selector(passcodeWasEnteredSuccessfully)]) {
                [self.delegate performSelector: @selector(passcodeWasEnteredSuccessfully)];
            }
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
    _OKButton.hidden = YES;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath: @"transform.translation.x"];
    animation.duration = 0.6;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAAnimationLinear];
    animation.values = @[@-12, @12, @-12, @12, @-6, @6, @-3, @3, @0];
    [_firstDigitTextField.layer addAnimation: animation forKey: @"shake"];
    [_secondDigitTextField.layer addAnimation: animation forKey: @"shake"];
    [_thirdDigitTextField.layer addAnimation: animation forKey: @"shake"];
    [_fourthDigitTextField.layer addAnimation: animation forKey: @"shake"];
    
	_failedAttempts++;
	
	if (_maxNumberOfAllowedFailedAttempts > 0 &&
		_failedAttempts == _maxNumberOfAllowedFailedAttempts &&
		[self.delegate respondsToSelector: @selector(maxNumberOfFailedAttemptsReached)]) {
		[self.delegate maxNumberOfFailedAttemptsReached];
		_failedAttempts = 0;
	}
//	Or, if you prefer by notifications:
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"maxNumberOfFailedAttemptsReached"
//														object: self
//													  userInfo: nil];
	
	if (_failedAttempts == 1) {
        _failedAttemptLabel.text =
        LTHPasscodeViewControllerStrings(@"1 Passcode Failed Attempt");
    }
	else {
		_failedAttemptLabel.text = [NSString stringWithFormat: LTHPasscodeViewControllerStrings(@"%i Passcode Failed Attempts"), _failedAttempts];
	}
	_failedAttemptLabel.layer.cornerRadius = kFailedAttemptLabelHeight * 0.65f;
	_failedAttemptLabel.clipsToBounds = true;
	_failedAttemptLabel.hidden = NO;
}


- (void)_logoutWasPressed {
	// Notify delegate that logout button was pressed
	if ([self.delegate respondsToSelector: @selector(logoutButtonWasPressed)]) {
		[self.delegate logoutButtonWasPressed];
	}
}


- (void)_resetTextFields {
    if (![_passcodeTextField isFirstResponder] && (!_isUsingTouchID || _useFallbackPasscode)) {
        [_passcodeTextField becomeFirstResponder];
    }
	_firstDigitTextField.secureTextEntry = NO;
	_secondDigitTextField.secureTextEntry = NO;
	_thirdDigitTextField.secureTextEntry = NO;
	_fourthDigitTextField.secureTextEntry = NO;
}


- (void)_resetUI {
	[self _resetTextFields];
	_failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
	_failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
    if (_failedAttempts == 0) _failedAttemptLabel.hidden = YES;
	
	_passcodeTextField.text = @"";
	if (_isUserConfirmingPasscode) {
		if (_isUserEnablingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.reenterPasscodeString);
        }
		else if (_isUserChangingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.reenterNewPasscodeString);
        }
	}
	else if (_isUserBeingAskedForNewPasscode) {
		if (_isUserEnablingPasscode || _isUserChangingPasscode) {
			_enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.enterNewPasscodeString);
		}
	}
	else {
        if (_isUserChangingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.enterOldPasscodeString);
        } else {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.enterPasscodeString);
        }
    }
	
	// Make sure nav bar for logout is off the screen
    if (_isUsingNavbar) {
        [self.navBar removeFromSuperview];
        self.navBar = nil;
    }
    _isUsingNavbar = NO;
    
    _OKButton.hidden = YES;
}


- (void)_resetUIForReEnteringNewPasscode {
	[self _resetTextFields];
	_passcodeTextField.text = @"";
	// If there's no passcode saved in Keychain,
    // the user is adding one for the first time, otherwise he's changing his passcode.
	NSString *savedPasscode = [LTHKeychainUtils getPasswordForUsername: _keychainPasscodeUsername
														 andServiceName: _keychainServiceName
																  error: nil];
	_enterPasscodeLabel.text = savedPasscode.length == 0 ? LTHPasscodeViewControllerStrings(self.enterPasscodeString) : LTHPasscodeViewControllerStrings(self.enterNewPasscodeString);
	
	_failedAttemptLabel.hidden = NO;
	_failedAttemptLabel.text = LTHPasscodeViewControllerStrings(@"Passcodes did not match. Try again.");
	_failedAttemptLabel.backgroundColor = [UIColor clearColor];
	_failedAttemptLabel.layer.borderWidth = 0;
	_failedAttemptLabel.layer.borderColor = [UIColor clearColor].CGColor;
	_failedAttemptLabel.textColor = _labelTextColor;
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
    if (_isUserSwitchingBetweenPasscodeModes &&
        (_isUserBeingAskedForNewPasscode || _isUserConfirmingPasscode)) {
        return !_isSimple;
    }
    
    return _isSimple;
}

#pragma mark - Notification Observers
- (void)_applicationDidEnterBackground {
	if ([self _doesPasscodeExist]) {
        if ([_passcodeTextField isFirstResponder]) {
            _useFallbackPasscode = NO;
			[_passcodeTextField resignFirstResponder];
        }
		// Without animation because otherwise it won't come down fast enough,
		// so inside iOS' multitasking view the app won't be covered by anything.
		if ([self _timerDuration] <= 0) {
            // This is here and the rest in willEnterForeground because when self is pushed
            // instead of presented as a modal,
            // the app would be visible from the multitasking view.
            if (_isCurrentlyOnScreen && !_displayedAsModal) return;
            
            [self showLockScreenWithAnimation:NO
                                   withLogout:NO
                               andLogoutTitle:nil];
        }
		else {
			_coverView.hidden = NO;
			if (![[UIApplication sharedApplication].keyWindow viewWithTag: _coverViewTag])
				[[UIApplication sharedApplication].keyWindow addSubview: _coverView];
		}
	}
}


- (void)_applicationDidBecomeActive {
    if(_isUsingTouchID && !_useFallbackPasscode) {
        _animatingView.hidden = YES;
        [_passcodeTextField resignFirstResponder];
    }
	_coverView.hidden = YES;
}


- (void)_applicationWillEnterForeground {
	if ([self _doesPasscodeExist] &&
		[self _didPasscodeTimerEnd]) {
        _useFallbackPasscode = NO;
        // This is here instead of didEnterBackground because when self is pushed
        // instead of presented as a modal,
        // the app would be visible from the multitasking view.
        if (!_displayedAsModal && !_displayedAsLockScreen && _isCurrentlyOnScreen) {
            [_passcodeTextField resignFirstResponder];
            [self.navigationController popViewControllerAnimated:NO];
            // This is like this because it screws up the navigation stack otherwise
            [self performSelector:@selector(showLockscreenWithoutAnimation)
                       withObject:nil
                       afterDelay:0.0];
        }
        else {
            [self showLockScreenWithAnimation:NO
                                   withLogout:NO
                               andLogoutTitle:nil];
        }
	}
}


- (void)_applicationWillResignActive {
	if ([self _doesPasscodeExist] && !([self isCurrentlyOnScreen] && [self displayedAsLockScreen])) {
        _useFallbackPasscode = NO;
		[self _saveTimerStartTime];
	}
}


#pragma mark - Init
+ (instancetype)sharedUser {
    __strong static LTHPasscodeViewController *sharedObject = nil;
    
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedObject = [[self alloc] init];
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
    if ([LTHKeychainUtils getPasswordForUsername:_keychainPasscodeIsSimpleUsername
                                  andServiceName:_keychainServiceName
                                           error:nil]) {
        _isSimple = [[LTHKeychainUtils getPasswordForUsername:_keychainPasscodeIsSimpleUsername
                                               andServiceName:_keychainServiceName
                                                        error:nil] boolValue];
    } else {
        _isSimple = YES;
    }
    
	[self _loadDefaults];
}


- (void)_loadDefaults {
    [self _loadMiscDefaults];
    [self _loadStringDefaults];
    [self _loadGapDefaults];
    [self _loadFontDefaults];
    [self _loadColorDefaults];
    [self _loadKeychainDefaults];
}


- (void)_loadMiscDefaults {
    _coverViewTag = 994499;
    _lockAnimationDuration = 0.25;
    _slideAnimationDuration = 0.15;
    _maxNumberOfAllowedFailedAttempts = 0;
    _usesKeychain = YES;
    _displayedAsModal = YES;
    _hidesBackButton = YES;
    _hidesCancelButton = YES;
    _allowUnlockWithTouchID = YES;
    _passcodeCharacter = @"\u2014"; // A longer "-";
    _localizationTableName = @"LTHPasscodeViewController";
}


- (void)_loadStringDefaults {
    self.enterOldPasscodeString = @"Enter your old passcode";
    self.enterPasscodeString = @"Enter your passcode";
    self.enablePasscodeString = @"Enable Passcode";
    self.changePasscodeString = @"Change Passcode";
    self.turnOffPasscodeString = @"Turn Off Passcode";
    self.reenterPasscodeString = @"Re-enter your passcode";
    self.reenterNewPasscodeString = @"Re-enter your new passcode";
    self.enterNewPasscodeString = @"Enter your new passcode";
    self.touchIDString = @"Unlock using Touch ID";
}


- (void)_loadGapDefaults {
    _iPadFontSizeModifier = 1.5;
    _iPhoneHorizontalGap = 40.0;
    _horizontalGap = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? _iPhoneHorizontalGap * _iPadFontSizeModifier : _iPhoneHorizontalGap;
    _verticalGap = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 60.0f : 25.0f;
    _modifierForBottomVerticalGap = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.6f : 3.0f;
    _failedAttemptLabelGap = _verticalGap * _modifierForBottomVerticalGap - 2.0f;
    _passcodeOverlayHeight = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 96.0f : 40.0f;
}


- (void)_loadFontDefaults {
    _labelFontSize = 15.0;
    _passcodeFontSize = 33.0;
    _labelFont = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
    [UIFont fontWithName: @"AvenirNext-Regular" size:_labelFontSize * _iPadFontSizeModifier] :
    [UIFont fontWithName: @"AvenirNext-Regular" size:_labelFontSize];
    _passcodeFont = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ?
    [UIFont fontWithName: @"AvenirNext-Regular" size: _passcodeFontSize * _iPadFontSizeModifier] :
    [UIFont fontWithName: @"AvenirNext-Regular" size: _passcodeFontSize];
}


- (void)_loadColorDefaults {
    // Backgrounds
    _backgroundColor = [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f];
    _passcodeBackgroundColor = [UIColor clearColor];
    _coverViewBackgroundColor = [UIColor colorWithRed:0.97f green:0.97f blue:1.0f alpha:1.00f];
    _failedAttemptLabelBackgroundColor =  [UIColor colorWithRed:0.8f green:0.1f blue:0.2f alpha:1.000f];
    _enterPasscodeLabelBackgroundColor = [UIColor clearColor];
    
    // Text
    _labelTextColor = [UIColor colorWithWhite:0.31f alpha:1.0f];
    _passcodeTextColor = [UIColor colorWithWhite:0.31f alpha:1.0f];
    _failedAttemptLabelTextColor = [UIColor whiteColor];
}


- (void)_loadKeychainDefaults {
    _keychainPasscodeUsername = @"demoPasscode";
    _keychainTimerStartUsername = @"demoPasscodeTimerStart";
    _keychainServiceName = @"demoServiceName";
    _keychainTimerDurationUsername = @"passcodeTimerDuration";
    _keychainPasscodeIsSimpleUsername = @"passcodeIsSimple";
}


- (void)_addObservers {
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationDidEnterBackground)
     name: UIApplicationDidEnterBackgroundNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationWillResignActive)
     name: UIApplicationWillResignActiveNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationDidBecomeActive)
     name: UIApplicationDidBecomeActiveNotification
     object: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector(_applicationWillEnterForeground)
     name: UIApplicationWillEnterForegroundNotification
     object: nil];
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
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if (_displayedAsLockScreen)
        return LTHiOS8 ? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskAll;
	// I'll be honest and mention I have no idea why this line of code below works.
	// Without it, if you present the passcode view as lockscreen (directly on the window)
	// and then inside of a modal, the orientation will be wrong.
	
	// If you could explain why, I'd be more than grateful :)
	return UIInterfaceOrientationMaskPortrait;
}


// All of the rotation handling is thanks to Håvard Fossli's - https://github.com/hfossli
// answer: http://stackoverflow.com/a/4960988/793916
- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification {
    /*
     This notification is most likely triggered inside an animation block,
     therefore no animation is needed to perform this nice transition.
     */
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
    if (LTHiOS8) {
        _animatingView.frame = self.view.frame;
    }
    else {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            _animatingView.frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.frame.size.width, [UIApplication sharedApplication].keyWindow.frame.size.height);
        }
        else {
            _animatingView.frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.frame.size.height, [UIApplication sharedApplication].keyWindow.frame.size.width);
        }
    }
}


// And to his AGWindowView: https://github.com/hfossli/AGWindowView
// Without the 'desiredOrientation' method, using showLockscreen in one orientation,
// then presenting it inside a modal in another orientation would display
// the view in the first orientation.
- (UIInterfaceOrientation)desiredOrientation {
    UIInterfaceOrientation statusBarOrientation =
    [[UIApplication sharedApplication] statusBarOrientation];
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

- (void)disablePasscodeWhenApplicationEntersBackground {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


+ (CGFloat)getStatusBarHeight {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
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
