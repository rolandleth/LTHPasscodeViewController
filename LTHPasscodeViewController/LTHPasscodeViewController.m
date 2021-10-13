//
//  PasscodeViewController.m
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import "LTHPasscodeViewController.h"
#import "LTHKeychainUtils.h"
#import <LocalAuthentication/LocalAuthentication.h>

#ifndef LTH_IS_APP_EXTENSION
#import "MEGA-Swift.h"
#endif

#define LTHiPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#define LTHFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithAttributes: @{NSFontAttributeName : _labelFont}].height
#else
// Thanks to Kent Nguyen - https://github.com/kentnguyen
#define LTHFailedAttemptLabelHeight [_failedAttemptLabel.text sizeWithFont:_labelFont].height
#endif

#ifndef LTHPasscodeViewControllerStrings
#define LTHPasscodeViewControllerStrings(key) \
[[NSBundle bundleWithPath:[[NSBundle bundleForClass:[LTHPasscodeViewController class]] pathForResource:@"LTHPasscodeViewController" ofType:@"bundle"]] localizedStringForKey:(key) value:@"" table:_localizationTableName]
#endif

@interface UIApplication (window)

+ (nullable UIWindow *)currentWindow;

@end

@implementation UIApplication (window)

+ (UIWindow *)currentWindow {
    UIWindow *window;
#ifdef LTH_IS_APP_EXTENSION
    window = [UIApplication sharedApplication].keyWindow;
#else
    window = [UIApplication sharedApplication].windows.firstObject;
#endif
    return window;
}

@end

@interface LTHPasscodeViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIView      *coverView;
@property (nonatomic, strong) UIView      *animatingView;
@property (nonatomic, strong) UIView      *complexPasscodeOverlayView;
@property (nonatomic, strong) UIView      *simplePasscodeView;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@property (nonatomic, strong) UITextField *passcodeTextField;
@property (nonatomic, strong) UILabel     *enterPasscodeInfoLabel;

@property (nonatomic, strong) NSMutableArray<UITextField *> *digitTextFieldsArray;

@property (nonatomic, strong) UILabel     *failedAttemptLabel;
@property (nonatomic, strong) UILabel     *eraseLocalDataLabel;
@property (nonatomic, strong) UILabel     *enterPasscodeLabel;
@property (nonatomic, strong) UIButton    *optionsButton;
@property (nonatomic, strong) UIView      *topBorder;
@property (nonatomic, strong) UIView      *bottomBorder;

@property (nonatomic, strong) NSString    *tempPasscode;
@property (nonatomic, assign) NSInteger   failedAttempts;

@property (nonatomic, assign) CGFloat     modifierForBottomVerticalGap;
@property (nonatomic, assign) CGFloat     fontSizeModifier;
@property (nonatomic, assign) CGFloat     keyboardHeight;
@property (nonatomic, assign) CGFloat     yOffsetFromCenter;

@property (nonatomic, assign) NSLayoutConstraint *optionsButtonConstraintTop;
@property (nonatomic, assign) NSLayoutConstraint *enterPasscodeConstraintCenterY;
@property (nonatomic, assign) NSLayoutConstraint *enterPasscodeConstraintTop;
@property (nonatomic, assign) BOOL        isResetPasscode;

@property (nonatomic, assign) BOOL        newPasscodeEqualsOldPasscode;
@property (nonatomic, assign) BOOL        passcodeAlreadyExists;
@property (nonatomic, assign) BOOL        usesKeychain;
@property (nonatomic, assign) BOOL        displayedAsModal;
@property (nonatomic, assign) BOOL        displayedAsLockScreen;
@property (nonatomic, assign) BOOL        isUsingNavBar;
@property (nonatomic, assign) BOOL        isCurrentlyOnScreen;
@property (nonatomic, assign) BOOL        isSimple; // YES by default
@property (nonatomic, assign) BOOL        isUserConfirmingPasscode;
@property (nonatomic, assign) BOOL        isUserBeingAskedForNewPasscode;
@property (nonatomic, assign) BOOL        isUserTurningPasscodeOff;
@property (nonatomic, assign) BOOL        isUserChangingPasscode;
@property (nonatomic, assign) BOOL        isUserEnablingPasscode;
@property (nonatomic, assign) BOOL        isUserSwitchingBetweenPasscodeModes; // simple/complex
@property (nonatomic, assign) BOOL        timerStartInSeconds;
@property (nonatomic, assign) BOOL        isUsingBiometrics;
@property (nonatomic, assign) BOOL        useFallbackPasscode;
@property (nonatomic, assign) BOOL        isAppNotificationsObserved;
@property (nonatomic, strong) LAContext   *biometricsContext;

@end

@implementation LTHPasscodeViewController

static const NSInteger LTHMinPasscodeDigits = 4;
static const NSInteger LTHMaxPasscodeDigits = 10;

#pragma mark - Public, class methods
+ (BOOL)doesPasscodeExist {
    return [[self sharedUser] _doesPasscodeExist];
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
    if ([LTHKeychainUtils getPasswordForUsername:_keychainPasscodeIsSimpleUsername
                                  andServiceName:_keychainServiceName
                                           error:nil]) {
        _isSimple = [[LTHKeychainUtils getPasswordForUsername:_keychainPasscodeIsSimpleUsername
                                               andServiceName:_keychainServiceName
                                                        error:nil] boolValue];
    } else {
        _isSimple = YES;
    }
    
    if ([LTHKeychainUtils getPasswordForUsername:_keychainPasscodeTypeUsername
                                  andServiceName:_keychainServiceName
                                           error:nil]) {
        _passcodeType = (PasscodeType)[[LTHKeychainUtils getPasswordForUsername:_keychainPasscodeTypeUsername
                                                                 andServiceName:_keychainServiceName
                                                                          error:nil] integerValue];
    } else {
        _passcodeType = PasscodeTypeFourDigits;
    }
    
    if (_isSimple) {
        _digitsCount = (_passcodeType == PasscodeTypeFourDigits) ? 4 : 6;
    } else {
        _passcodeType = PasscodeTypeCustomAlphanumeric;
    }
    
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
    return now - [self _timerStartTime] >= [self _timerDuration]
    || [self _timerStartTime] == -1
    || now <= [self _timerStartTime];
    // If the date was set in the past, this would return false.
    // It won't register as false, even right as it is being enabled,
    // because the saving alone takes 0.002+ seconds on a MBP 2.6GHz i7.
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
    [LTHKeychainUtils deleteItemForUsername:_keychainPasscodeTypeUsername
                             andServiceName:_keychainServiceName
                                      error:nil];
    [LTHKeychainUtils deleteItemForUsername:_keychainPasscodeIsSimpleUsername
                             andServiceName:_keychainServiceName
                                      error:nil];
    if (!_isResetPasscode) {
        _passcodeType = PasscodeTypeFourDigits;
        _isSimple = YES;
        _digitsCount = 4;
        [self _setupDigitFields];
    } else {
        _isResetPasscode = NO;
    }
}


- (void)_savePasscode:(NSString *)passcode {
    if (!_passcodeAlreadyExists &&
        [self.delegate respondsToSelector:@selector(passcodeWasEnabled)]) {
        [self.delegate passcodeWasEnabled];
    }
    
    _passcodeAlreadyExists = YES;
    
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
    [LTHKeychainUtils storeUsername:_keychainPasscodeTypeUsername
                        andPassword:[NSString stringWithFormat:@"%ld", (long)_passcodeType]
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


- (void)resetPasscode {
    if ([self _doesPasscodeExist]) {
        NSString *passcode = [self _passcode];
        _isResetPasscode = YES;
        [self _deletePasscode];
        [self _savePasscode:passcode];
    }
}

- (BOOL)isLockscreenPresent {
    return self.isCurrentlyOnScreen && self.displayedAsLockScreen;
}

- (void)_handleBiometricsFailureAndDisableIt:(BOOL)disableBiometrics {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (disableBiometrics) {
            self.isUsingBiometrics = NO;
            self.allowUnlockWithBiometrics = NO;
        }
        
        self.useFallbackPasscode = YES;
        self.animatingView.hidden = NO;
        
        BOOL usingNavBar = self.isUsingNavBar;
        NSString *logoutTitle = usingNavBar ? self.navBar.items.firstObject.leftBarButtonItem.title : @"";
        
        [self _resetUI];
        
        if (usingNavBar) {
            self.isUsingNavBar = usingNavBar;
            [self _setupNavBarWithLogoutTitle:logoutTitle];
        }
    });
    
    self.biometricsContext = nil;
}

- (void)_setupFingerPrint {
    if (!self.biometricsContext && _allowUnlockWithBiometrics && !_useFallbackPasscode) {
        self.biometricsContext = [[LAContext alloc] init];
        
        NSError *error = nil;
        if ([self.biometricsContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            if (error) {
                return;
            }
            
            if (self.biometricsContext.biometryType == LABiometryTypeFaceID) {
                    self.biometricsDetailsString = @"Unlock using Face ID";
            }
            
            _isUsingBiometrics = YES;
            [_passcodeTextField resignFirstResponder];
            _animatingView.hidden = YES;
            
            // Authenticate User
            [self.biometricsContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                   localizedReason:LTHPasscodeViewControllerStrings(self.biometricsDetailsString)
                                             reply:^(BOOL success, NSError *error) {
                
                if (error || !success) {
                    [self _handleBiometricsFailureAndDisableIt:false];
                    
                    if ([self.delegate respondsToSelector: @selector(biometricsAuthenticationFailed)]) {
                        [self.delegate performSelector: @selector(biometricsAuthenticationFailed)];
                    }
                    
                    return;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self _dismissMe];
                    
                    if ([self.delegate respondsToSelector: @selector(passcodeWasEnteredSuccessfully)]) {
                        [self.delegate performSelector: @selector(passcodeWasEnteredSuccessfully)];
                    }
                });
                
                self.biometricsContext = nil;
            }];
        }
        else {
            [self _handleBiometricsFailureAndDisableIt:true];
        }
    }
    else {
        [self _handleBiometricsFailureAndDisableIt:true];
    }
}


- (void)_saveAllowUnlockWithBiometrics {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(saveAllowUnlockWithBiometrics:)]) {
        [self.delegate saveAllowUnlockWithBiometrics:_allowUnlockWithBiometrics];
        
        return;
    }
    
    [LTHKeychainUtils storeUsername:_keychainAllowUnlockWithBiometrics
                        andPassword:[NSString stringWithFormat: @"%d",
                                     _allowUnlockWithBiometrics]
                     forServiceName:_keychainServiceName
                     updateExisting:YES
                              error:nil];
}



- (BOOL)_allowUnlockWithBiometrics {
    if (!_usesKeychain &&
        [self.delegate respondsToSelector:@selector(allowUnlockWithBiometrics)]) {
        return [self.delegate allowUnlockWithBiometrics];
    }
    
    NSString *keychainValue = [LTHKeychainUtils getPasswordForUsername:_keychainAllowUnlockWithBiometrics
                                                        andServiceName:_keychainServiceName
                                                                 error:nil];
    if (!keychainValue) return YES;
    return keychainValue.boolValue;
}


- (void)setAllowUnlockWithBiometrics:(BOOL)setAllowUnlockWithBiometrics {
    _allowUnlockWithBiometrics = setAllowUnlockWithBiometrics;
    [self _saveAllowUnlockWithBiometrics];
}


- (void)setDigitsCount:(NSInteger)digitsCount {
    // If a passcode exists, don't allow the changing of the number of digits.
    if ([self _doesPasscodeExist]) { return; }
    
    if (digitsCount < LTHMinPasscodeDigits) {
        digitsCount = LTHMinPasscodeDigits;
    }
    else if (digitsCount > LTHMaxPasscodeDigits) {
        digitsCount = LTHMaxPasscodeDigits;
    }
    
    _digitsCount = digitsCount;
    
    // If we haven't loaded yet, do nothing,
    // _setupDigitFields will be called in viewDidLoad.
    if (!self.isViewLoaded) { return; }
    [self _setupDigitFields];
}

- (void)setPasscodeType:(PasscodeType)passcodeType {
    if (_passcodeType == passcodeType) { return; }
    _passcodeType = passcodeType;
}

- (void)setPasscodeTypeAndInputArea:(PasscodeType)passcodeType {
    _passcodeTextField.text = @"";
    [self setPasscodeType:passcodeType];
    
    if (passcodeType != PasscodeTypeCustomAlphanumeric) {
        _digitsCount = (passcodeType == PasscodeTypeSixDigits) ? 6 : 4;
        [self _setupDigitFields];
    }
    _isUserSwitchingBetweenPasscodeModes = YES;
    _failedAttemptLabel.hidden = YES;
    [self setIsSimple:!(passcodeType == PasscodeTypeCustomAlphanumeric) inViewController:nil asModal:self.displayedAsModal];
}

- (void)keyboardHasHeight:(NSNotification *)notification {
    _keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [self setUpOptionButtonLocation];
}

- (void)setUpOptionButtonLocation {
    _passcodeButtonGap = UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])? 0 : _verticalGap;
    _optionsButtonConstraintTop.constant = [self calculateOptionsButtonTopGap];
}

- (CGFloat)calculateOptionsButtonTopGap {
    return self.view.frame.size.height - _keyboardHeight - _passcodeButtonGap - _optionsButton.frame.size.height;
}

- (void)calculateOffsetGap {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(orientation)) {
        _verticalOffset = LTHiPad? -110 : -65;
        _passcodeButtonGap = 0;
    } else {
        _verticalOffset = -5;
        _passcodeButtonGap = _verticalGap;
    }
    if (_displayedAsLockScreen && _isUsingNavBar) {
        _verticalOffset += 50;
    }
    _yOffsetFromCenter = _verticalOffset - CGRectGetHeight(UIApplication.currentWindow.bounds) * 0.24;
}

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
    [self _setupOptionsButton];
    
    // If on first launch we have a passcode, the number of digits should equal that.
    if ([self _doesPasscodeExist]) {
        if (_isSimple) {
            _digitsCount = [self _passcode].length;
        }
    }
    [self _setupDigitFields];
    
    _passcodeTextField = [[UITextField alloc] initWithFrame: CGRectZero];
    _passcodeTextField.textAlignment = NSTextAlignmentCenter;
    _passcodeTextField.delegate = self;
    _passcodeTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _passcodeTextField.returnKeyType = UIReturnKeyGo;
    _passcodeTextField.enablesReturnKeyAutomatically = YES;
    
    [self.view setNeedsUpdateConstraints];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHasHeight:) name:UIKeyboardWillShowNotification object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.isAppNotificationsObserved) {
        [self _addObservers];
        self.isAppNotificationsObserved = YES;
    }
    
    _animatingView.hidden = NO;
    _backgroundImageView.image = _backgroundImage;
    
    if (!_passcodeTextField.isFirstResponder && (!_isUsingBiometrics || _isUserChangingPasscode || _isUserBeingAskedForNewPasscode || _isUserConfirmingPasscode || _isUserEnablingPasscode || _isUserSwitchingBetweenPasscodeModes || _isUserTurningPasscodeOff)) {
        [_passcodeTextField becomeFirstResponder];
        _animatingView.hidden = NO;
    }
    if (_isUsingBiometrics && !_isUserChangingPasscode && !_isUserBeingAskedForNewPasscode && !_isUserConfirmingPasscode && !_isUserEnablingPasscode && !_isUserSwitchingBetweenPasscodeModes && !_isUserTurningPasscodeOff) {
        [_passcodeTextField resignFirstResponder];
        _animatingView.hidden = _isUsingBiometrics;
    }
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _animatingView.frame = self.view.bounds;
    [self setUpOptionButtonLocation];
}


- (void)viewWillDisappear:(BOOL)animated {
    // If _isCurrentlyOnScreen is true at this point,
    // it means the back button was tapped, so we need to reset.
    if ([self isMovingFromParentViewController] && !_hidesBackButton && _isCurrentlyOnScreen) {
        [self _close];
        return;
    }
    
    [super viewWillDisappear:animated];
    
    if (!_displayedAsModal && !_displayedAsLockScreen) {
        [self textFieldShouldEndEditing:_passcodeTextField];
    }
}


#ifndef LTH_IS_APP_EXTENSION
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        self.view.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    }
}
#endif


- (void)_cancelAndDismissMe {
    _isCurrentlyOnScreen = NO;
    _isUserBeingAskedForNewPasscode = NO;
    _isUserChangingPasscode = NO;
    _isUserConfirmingPasscode = NO;
    _isUserEnablingPasscode = NO;
    _isUserTurningPasscodeOff = NO;
    _isUserSwitchingBetweenPasscodeModes = NO;
    
    if (![self _doesPasscodeExist]) {
        _passcodeType = PasscodeTypeFourDigits;
        _isSimple = YES;
        _digitsCount = 4;
    }
    [self _setupDigitFields];
    [self _resetUI];
    [_passcodeTextField resignFirstResponder];
    
    if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWillClose)]) {
        [self.delegate performSelector: @selector(passcodeViewControllerWillClose)];
    }
    
    if (_displayedAsModal) [self dismissViewControllerAnimated:YES completion:nil];
    else if (!_displayedAsLockScreen) [self.navigationController popViewControllerAnimated:YES];
}


- (void)_dismissMe {
    _failedAttempts = 0;
    _isCurrentlyOnScreen = NO;
    [self _resetUI];
    [_passcodeTextField resignFirstResponder];
    [UIView animateWithDuration: _lockAnimationDuration animations: ^{
        if (self.displayedAsLockScreen) {
            self.view.center = CGPointMake(self.view.center.x, self.view.center.y * 2.f);
        }
        else {
            // Delete from Keychain
            if (self.isUserTurningPasscodeOff) {
                [self _deletePasscode];
            }
            // Update the Keychain if adding or changing passcode
            else {
                [self _savePasscode:self.tempPasscode];
                //finalize type switching
                if (self.isUserSwitchingBetweenPasscodeModes) {
                    self.isUserConfirmingPasscode = NO;
                    [self setIsSimple:!self.isSimple
                     inViewController:nil
                              asModal:self.displayedAsModal];
                }
            }
        }
    } completion: ^(BOOL finished) {
        if ([self.delegate respondsToSelector: @selector(passcodeViewControllerWillClose)]) {
            [self.delegate performSelector: @selector(passcodeViewControllerWillClose)];
        }
        
        if (self.displayedAsLockScreen) {
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
        else if (self.displayedAsModal) {
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        }
        else if (!self.displayedAsLockScreen) {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }];
}


#pragma mark - UI setup
- (void)_setupNavBarWithLogoutTitle:(NSString *)logoutTitle {
    // Navigation Bar with custom UI
    UIView *patchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication currentWindow].frame.size.width, self.view.safeAreaInsets.top)];
    patchView.backgroundColor = UIColor.clearColor;
    patchView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:patchView];
    
    self.navBar =
    [[UINavigationBar alloc] initWithFrame:CGRectMake(0, patchView.frame.size.height,
                                                      [UIApplication currentWindow].frame.size.width, 44)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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
    [self.view addSubview:self.navBar];
}

- (void)_setupViews {
    _coverView = [[UIView alloc] initWithFrame: CGRectZero];
    _coverView.backgroundColor = _coverViewBackgroundColor;
    _coverView.frame = self.view.frame;
    _coverView.userInteractionEnabled = NO;
    _coverView.tag = _coverViewTag;
    _coverView.hidden = YES;
    [[UIApplication currentWindow] addSubview: _coverView];
    
    _complexPasscodeOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
    _complexPasscodeOverlayView.backgroundColor = UIColor.mnz_background;
    _complexPasscodeOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self _setupPasscodeOverlayBorder];
    
    _simplePasscodeView = [[UIView alloc] initWithFrame:CGRectZero];
    _simplePasscodeView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_animatingView addSubview:_complexPasscodeOverlayView];
    [_animatingView addSubview:_simplePasscodeView];
}


- (void)_setupLabels {
    _enterPasscodeLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    _enterPasscodeLabel.backgroundColor = _enterPasscodeLabelBackgroundColor;
    _enterPasscodeLabel.numberOfLines = 0;
    _enterPasscodeLabel.textColor = _labelTextColor;
    _enterPasscodeLabel.font = _labelFont;
    _enterPasscodeLabel.textAlignment = NSTextAlignmentCenter;
    [_animatingView addSubview: _enterPasscodeLabel];
    
    _enterPasscodeInfoLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    _enterPasscodeInfoLabel.backgroundColor = _enterPasscodeLabelBackgroundColor;
    _enterPasscodeInfoLabel.numberOfLines = 0;
    _enterPasscodeInfoLabel.textColor = _labelTextColor;
    _enterPasscodeInfoLabel.font = _labelFont;
    _enterPasscodeInfoLabel.textAlignment = NSTextAlignmentCenter;
    _enterPasscodeInfoLabel.hidden = !_displayAdditionalInfoDuringSettingPasscode;
    [_animatingView addSubview: _enterPasscodeInfoLabel];
    
    // It is also used to display the "Passcodes did not match" error message
    // if the user fails to confirm the passcode.
    _failedAttemptLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    _failedAttemptLabel.text = LTHPasscodeViewControllerStrings(@"1 Passcode failed attempt");
    _failedAttemptLabel.numberOfLines = 0;
    _failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
    _failedAttemptLabel.hidden = YES;
    _failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
    _failedAttemptLabel.font = _labelFont;
    _failedAttemptLabel.textAlignment = NSTextAlignmentCenter;
    [_animatingView addSubview: _failedAttemptLabel];
    
    _eraseLocalDataLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    _eraseLocalDataLabel.text = NSLocalizedString(@"failedAttempstSectionTitle", @"Footer text that explain what will happen if reach the max number of failed attempts");
    _eraseLocalDataLabel.numberOfLines = 3;
    _eraseLocalDataLabel.backgroundColor = _eraseLocalDataLabelBackgroundColor;
    _eraseLocalDataLabel.hidden = YES;
    _eraseLocalDataLabel.textColor = _eraseLocalDataLabelTextColor;
    _eraseLocalDataLabel.font = _labelFont;
    _eraseLocalDataLabel.textAlignment = NSTextAlignmentCenter;
    _eraseLocalDataLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_animatingView addSubview: _eraseLocalDataLabel];
    
    _enterPasscodeLabel.text = _isUserChangingPasscode ? LTHPasscodeViewControllerStrings(self.enterOldPasscodeString) : LTHPasscodeViewControllerStrings(self.enterPasscodeString);
    _enterPasscodeInfoLabel.text = LTHPasscodeViewControllerStrings(self.enterPasscodeInfoString);
    
    _enterPasscodeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _enterPasscodeInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _failedAttemptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _eraseLocalDataLabel.translatesAutoresizingMaskIntoConstraints = NO;
}


- (void)_setupDigitFields {
    [_digitTextFieldsArray enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
        [textField removeFromSuperview];
    }];
    [_digitTextFieldsArray removeAllObjects];
    
    for (int i = 0; i < _digitsCount; i++) {
        UITextField *digitTextField = [self _makeDigitField];
        [_digitTextFieldsArray addObject:digitTextField];
        [_simplePasscodeView addSubview:digitTextField];
    }
    
    [self.view setNeedsUpdateConstraints];
}


- (UITextField *)_makeDigitField{
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.backgroundColor = _passcodeBackgroundColor;
    field.textAlignment = NSTextAlignmentCenter;
    field.text = _passcodeCharacter;
    field.textColor = _passcodeTextColor;
    field.font = _passcodeFont;
    field.delegate = self;
    field.secureTextEntry = NO;
    field.tintColor = [UIColor clearColor];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    [field setBorderStyle:UITextBorderStyleNone];
    return field;
}

- (void)_setupOptionsButton {
    _optionsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_optionsButton setTitle:NSLocalizedString(@"Passcode Options", @"Button text to change the passcode type.") forState:UIControlStateNormal];
    _optionsButton.titleLabel.font = _optionsButtonFont;
    [_optionsButton setTitleColor:_optionsButtonTextColor forState:UIControlStateNormal];
    [_optionsButton sizeToFit];
    [_optionsButton addTarget:self action:@selector(optionsCodeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_animatingView addSubview:self.optionsButton];
    _optionsButton.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)_setupPasscodeOverlayBorder {
    _topBorder = [[UIView alloc] initWithFrame:CGRectZero];
    _topBorder.backgroundColor = _textFieldBorderColor;
    [_complexPasscodeOverlayView addSubview:_topBorder];
    _topBorder.translatesAutoresizingMaskIntoConstraints = NO;
    
    _bottomBorder = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomBorder.backgroundColor = _textFieldBorderColor;
    [_complexPasscodeOverlayView addSubview:_bottomBorder];
    _bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    [self.view removeConstraints:self.view.constraints];
    [_animatingView removeConstraints:_animatingView.constraints];
    
    _simplePasscodeView.hidden = !self.isSimple;
    
    _complexPasscodeOverlayView.hidden = self.isSimple;
    _passcodeTextField.hidden = self.isSimple;
    // This would make the existing text to be cleared after dismissing
    // the keyboard, then focusing the text field again.
    // When simple, the text field only acts as a proxy and is hidden anyway.
    _passcodeTextField.secureTextEntry = !self.isSimple;
    _passcodeTextField.keyboardType = self.isSimple ? UIKeyboardTypeNumberPad : UIKeyboardTypeASCIICapable;
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
    
    [self calculateOffsetGap];
    NSLayoutConstraint *enterPasscodeConstraintCenterX =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
    _enterPasscodeConstraintCenterY =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeLabel
                                 attribute: NSLayoutAttributeCenterY
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterY
                                multiplier: 1.0f
                                  constant: _yOffsetFromCenter];
    [self.view addConstraint: enterPasscodeConstraintCenterX];
    [self.view addConstraint: _enterPasscodeConstraintCenterY];
    
    NSLayoutConstraint *enterPasscodeInfoConstraintCenterX =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeInfoLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
    NSLayoutConstraint *enterPasscodeInfoConstraintCenterY =
    [NSLayoutConstraint constraintWithItem: _enterPasscodeInfoLabel
                                 attribute: NSLayoutAttributeCenterY
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _simplePasscodeView
                                 attribute: NSLayoutAttributeCenterY
                                multiplier: 1.0f
                                  constant: 50];
    [self.view addConstraint: enterPasscodeInfoConstraintCenterX];
    [self.view addConstraint: enterPasscodeInfoConstraintCenterY];
    
    if (self.isSimple) {
        [_digitTextFieldsArray enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat constant = idx == 0 ? 0 : self.horizontalGap;
            UIView *toItem = idx == 0 ? self.simplePasscodeView : self.digitTextFieldsArray[idx - 1];
            
            NSLayoutConstraint *digitX =
            [NSLayoutConstraint constraintWithItem: textField
                                         attribute: NSLayoutAttributeLeading
                                         relatedBy: NSLayoutRelationEqual
                                            toItem: toItem
                                         attribute: NSLayoutAttributeLeading
                                        multiplier: 1.0f
                                          constant: constant];
            
            NSLayoutConstraint *top =
            [NSLayoutConstraint constraintWithItem: textField
                                         attribute: NSLayoutAttributeTop
                                         relatedBy: NSLayoutRelationEqual
                                            toItem: self.simplePasscodeView
                                         attribute: NSLayoutAttributeTop
                                        multiplier: 1.0f
                                          constant: 0];
            
            NSLayoutConstraint *bottom =
            [NSLayoutConstraint constraintWithItem: textField
                                         attribute: NSLayoutAttributeBottom
                                         relatedBy: NSLayoutRelationEqual
                                            toItem: self.simplePasscodeView
                                         attribute: NSLayoutAttributeBottom
                                        multiplier: 1.0f
                                          constant: 0];
            
            [self.view addConstraint:digitX];
            [self.view addConstraint:top];
            [self.view addConstraint:bottom];
            
            if (idx == self.digitTextFieldsArray.count - 1) {
                NSLayoutConstraint *trailing =
                [NSLayoutConstraint constraintWithItem: textField
                                             attribute: NSLayoutAttributeTrailing
                                             relatedBy: NSLayoutRelationEqual
                                                toItem: self.simplePasscodeView
                                             attribute: NSLayoutAttributeTrailing
                                            multiplier: 1.0f
                                              constant: 0];
                
                [self.view addConstraint:trailing];
            }
        }];
        
        NSLayoutConstraint *simplePasscodeViewX =
        [NSLayoutConstraint constraintWithItem: _simplePasscodeView
                                     attribute: NSLayoutAttributeCenterX
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeCenterX
                                    multiplier: 1.0
                                      constant: 0];
        
        NSLayoutConstraint *simplePasscodeViewY =
        [NSLayoutConstraint constraintWithItem: _simplePasscodeView
                                     attribute: NSLayoutAttributeCenterY
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _enterPasscodeLabel
                                     attribute: NSLayoutAttributeBottom
                                    multiplier: 1.0
                                      constant: _verticalGap];
        
        
        [self.view addConstraint:simplePasscodeViewX];
        [self.view addConstraint:simplePasscodeViewY];
        
    }
    else {
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_passcodeTextField);
        
        //TODO: specify different offsets through metrics
        NSArray *constraints =
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_passcodeTextField]-10-|"
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
        
        NSLayoutConstraint *overlayViewLeftConstraint =
        [NSLayoutConstraint constraintWithItem: _complexPasscodeOverlayView
                                     attribute: NSLayoutAttributeLeading
                                     relatedBy: NSLayoutRelationEqual
                                        toItem: _animatingView
                                     attribute: NSLayoutAttributeLeading
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
        
        [_topBorder.widthAnchor constraintEqualToAnchor:_complexPasscodeOverlayView.widthAnchor].active = YES;
        [_topBorder.centerXAnchor constraintEqualToAnchor:_complexPasscodeOverlayView.centerXAnchor].active = YES;
        [_topBorder.topAnchor constraintEqualToAnchor:_complexPasscodeOverlayView.topAnchor].active = YES;
        [_topBorder.heightAnchor constraintEqualToConstant:1.0f].active = YES;
        
        [_bottomBorder.widthAnchor constraintEqualToAnchor:_complexPasscodeOverlayView.widthAnchor].active = YES;
        [_bottomBorder.centerXAnchor constraintEqualToAnchor:_complexPasscodeOverlayView.centerXAnchor].active = YES;
        [_bottomBorder.topAnchor constraintEqualToAnchor:_complexPasscodeOverlayView.bottomAnchor constant:-1.0f].active = YES;
        [_bottomBorder.heightAnchor constraintEqualToConstant:1.0f].active = YES;
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
    NSLayoutConstraint *failedAttemptLabelHeight =
    [NSLayoutConstraint constraintWithItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeHeight
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: nil
                                 attribute: NSLayoutAttributeNotAnAttribute
                                multiplier: 1.0f
                                  constant: LTHFailedAttemptLabelHeight + 6.0f];
    [self.view addConstraint:failedAttemptLabelCenterX];
    [self.view addConstraint:failedAttemptLabelCenterY];
    [self.view addConstraint:failedAttemptLabelHeight];
    
    NSLayoutConstraint *eraseLocalDataLabelCenterX =
    [NSLayoutConstraint constraintWithItem: _eraseLocalDataLabel
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
    NSLayoutConstraint *eraseLocalDataLabelCenterY =
    [NSLayoutConstraint constraintWithItem: _eraseLocalDataLabel
                                 attribute: NSLayoutAttributeCenterY
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _failedAttemptLabel
                                 attribute: NSLayoutAttributeBottom
                                multiplier: 1.0f
                                  constant: _verticalGap + 5];
    NSLayoutConstraint *eraseLocalDataLabelLeading =
    [NSLayoutConstraint constraintWithItem: _eraseLocalDataLabel
                                 attribute: NSLayoutAttributeLeading
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeLeading
                                multiplier: 1.0f
                                  constant: _horizontalGap];
    [self.view addConstraint:eraseLocalDataLabelCenterX];
    [self.view addConstraint:eraseLocalDataLabelCenterY];
    [self.view addConstraint:eraseLocalDataLabelLeading];
    
    NSLayoutConstraint *optionsButtonConstraintCenterX =
    [NSLayoutConstraint constraintWithItem: _optionsButton
                                 attribute: NSLayoutAttributeCenterX
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: _animatingView
                                 attribute: NSLayoutAttributeCenterX
                                multiplier: 1.0f
                                  constant: 0.0f];
    _optionsButtonConstraintTop =
    [NSLayoutConstraint constraintWithItem: _optionsButton
                                 attribute: NSLayoutAttributeTop
                                 relatedBy: NSLayoutRelationEqual
                                    toItem: self.view
                                 attribute: NSLayoutAttributeTop
                                multiplier: 1.0f
                                  constant: [self calculateOptionsButtonTopGap]];
    [self.view addConstraint: optionsButtonConstraintCenterX];
    [self.view addConstraint: _optionsButtonConstraintTop];
}


#pragma mark - Displaying
- (void)showLockscreenWithoutAnimation {
    [self showLockScreenWithAnimation:NO withLogout:NO andLogoutTitle:nil];
}

- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle {
    [self showLockScreenOver:[UIApplication currentWindow] withAnimation:animated withLogout:hasLogout andLogoutTitle:logoutTitle];
}

- (void)showLockScreenOver:(UIView *)superview withAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle {
    [self _prepareAsLockScreen];
    
    // Add nav bar & logout button if specified
    if (hasLogout) {
        _isUsingNavBar = hasLogout;
        [self _setupNavBarWithLogoutTitle:logoutTitle];
    }
    
    // In case the user leaves the app while the lockscreen is already active.
    if (_isCurrentlyOnScreen) { return; }
    _isCurrentlyOnScreen = YES;
    
    [superview addSubview: self.view];
    
    // All this hassle because a view added to UIWindow does not rotate automatically
    // and if we would have added the view anywhere else, it wouldn't display properly
    // (having a modal on screen when the user leaves the app, for example).
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
    CGPoint superviewCenter = CGPointMake(superview.center.x, superview.center.y);
    CGPoint newCenter;
    [self statusBarFrameOrOrientationChanged:nil];
    self.view.center = CGPointMake(self.view.center.x, self.view.center.y * -1.f);
    newCenter = CGPointMake(superviewCenter.x,
                            superviewCenter.y + self.navigationController.navigationBar.frame.size.height / 2);
    
    [UIView animateWithDuration: animated ? _lockAnimationDuration : 0 animations: ^{
        self.view.center = newCenter;
    }];
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
    
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [viewController presentViewController:navController
                                 animated:YES
                               completion:nil];
    [self rotateAccordingToStatusBarOrientationAndSupportedOrientations];
}


- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController
                                        asModal:(BOOL)isModal {
    _displayedAsModal = isModal;
    _passcodeAlreadyExists = NO;
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
    
    self.title = @"";
    [self _resetUI];
    [self _setupFingerPrint];
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
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == _passcodeTextField) { return true; }
    
    [_passcodeTextField becomeFirstResponder];
    
    UITextPosition *end = _passcodeTextField.endOfDocument;
    UITextRange *range = [_passcodeTextField textRangeFromPosition:end toPosition:end];
    
    [_passcodeTextField setSelectedTextRange:range];
    
    return false;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ((!_displayedAsLockScreen && !_displayedAsModal) || (_isUsingBiometrics || !_useFallbackPasscode)) {
        return YES;
    }
    return !_isCurrentlyOnScreen;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if ([string isEqualToString: @"\n"]) return NO;
    
    NSString *typedString = [textField.text stringByReplacingCharactersInRange: range
                                                                    withString: string];
    
    if (self.isSimple) {
        if ([string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound) {
            return NO;
        } else {
            [_digitTextFieldsArray enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
                textField.secureTextEntry = typedString.length > idx;
            }];
            
            if (typedString.length == _digitsCount) {
                // Make the last bullet show up
                [self performSelector: @selector(_validatePasscode:)
                           withObject: typedString
                           afterDelay: 0.15];
            }
            
            if (typedString.length > _digitsCount) return NO;
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (_passcodeType != PasscodeTypeCustomAlphanumeric) {
        NSInteger inputLength = _passcodeTextField.text.length;
        NSInteger expectLength = _passcodeType == PasscodeTypeFourDigits ? 4 : 6;
        if (inputLength != expectLength) {
            [textField becomeFirstResponder];
            return NO;
        }
    }
    [self _validateComplexPasscode];
    return YES;
}

#pragma mark - Validation
- (void)_validateComplexPasscode {
    [self _validatePasscode:_passcodeTextField.text];
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
            // User entered the confirmation Passcode incorrectly, or the passcode is the same as the old one, start over.
            _newPasscodeEqualsOldPasscode = [typedString isEqualToString:savedPasscode];
            if (![typedString isEqualToString:_tempPasscode] || _newPasscodeEqualsOldPasscode) {
                [self performSelector:@selector(_reAskForNewPasscode)
                           withObject:nil
                           afterDelay:_slideAnimationDuration];
            }
            // User entered the confirmation Passcode correctly.
            else {
                [self _dismissMe];
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
    _eraseLocalDataLabel.hidden = YES;
    
    CATransition *transition = [CATransition animation];
    [self performSelector: @selector(_resetUI) withObject: nil afterDelay: 0.1f];
    [_passcodeTextField becomeFirstResponder];
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
    [self performSelector: @selector(_resetUIForReEnteringNewPasscode)
               withObject: nil
               afterDelay: 0.1f];
    [_passcodeTextField becomeFirstResponder];
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
    _eraseLocalDataLabel.hidden = YES;
    
    CATransition *transition = [CATransition animation];
    [self performSelector: @selector(_resetUI) withObject: nil afterDelay: 0.1f];
    [_passcodeTextField becomeFirstResponder];
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
    [_passcodeTextField becomeFirstResponder];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath: @"transform.translation.x"];
    animation.duration = 0.6;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAAnimationLinear];
    animation.values = @[@-12, @12, @-12, @12, @-6, @6, @-3, @3, @0];
    
    [_digitTextFieldsArray enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
        [textField.layer addAnimation:animation forKey:@"shake"];
    }];
    
    _failedAttempts++;
    
    if (_maxNumberOfAllowedFailedAttempts > 0 &&
        _failedAttempts >= _maxNumberOfAllowedFailedAttempts &&
        [self.delegate respondsToSelector: @selector(maxNumberOfFailedAttemptsReached)]) {
        [self.delegate maxNumberOfFailedAttemptsReached];
    }
    
    NSString *translationText;
    if (_failedAttempts == 1) {
        translationText = LTHPasscodeViewControllerStrings(@"1 Passcode failed attempt");
    }
    else {
        translationText = [NSString stringWithFormat:LTHPasscodeViewControllerStrings(@"%i Passcode failed attempts"), _failedAttempts];
    }
    // To give it some padding. Since it's center-aligned,
    // it will automatically distribute the extra space.
    // Ironically enough, I found 5 spaces to be the best looking.
    _failedAttemptLabel.text = [NSString stringWithFormat:@"%@     ", translationText];
    
    _failedAttemptLabel.layer.cornerRadius = LTHiPad ? 19 : 14;
    _failedAttemptLabel.clipsToBounds = true;
    _failedAttemptLabel.hidden = NO;
    
    if (_failedAttempts >= 5) {
        _eraseLocalDataLabel.hidden = NO;
    }
}


- (void)_logoutWasPressed {
    // Notify delegate that logout button was pressed
    if ([self.delegate respondsToSelector: @selector(logoutButtonWasPressed)]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"proceedToLogout", @"Title to confirm that you want to logout") message:NSLocalizedString(@"When you logout, files from your Offline section will be deleted from your device and ongoing transfers will be cancelled.", @"Warning message to alert user about logout in My Account section if has offline files and transfers in progress.") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.delegate logoutButtonWasPressed];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


- (void)_resetTextFields {
    // If _allowUnlockWithBiometrics == true, but _isUsingBiometrics == false,
    // it means we're just launching, and we don't want the keyboard to show.
    if (![_passcodeTextField isFirstResponder]
        && (!(_allowUnlockWithBiometrics || _isUsingBiometrics) || _useFallbackPasscode)) {
        // It seems like there's a glitch with how the alert gets removed when hitting
        // cancel in the Touch ID prompt. In some cases, the keyboard is present, but invisible
        // after dismissing the alert unless we call becomeFirstResponder with a short delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.passcodeTextField becomeFirstResponder];
        });
    }
    
    [_digitTextFieldsArray enumerateObjectsUsingBlock:^(UITextField * _Nonnull textField, NSUInteger idx, BOOL * _Nonnull stop) {
        textField.secureTextEntry = NO;
    }];
}


- (void)_resetUI {
    [self _resetTextFields];
    _failedAttemptLabel.backgroundColor	= _failedAttemptLabelBackgroundColor;
    _failedAttemptLabel.textColor = _failedAttemptLabelTextColor;
    if (_failedAttempts == 0) {
        _failedAttemptLabel.hidden = YES;
        _eraseLocalDataLabel.hidden = YES;
    }
    
    _passcodeTextField.text = @"";
    if (_isUserConfirmingPasscode) {
        if (_isUserEnablingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.reenterPasscodeString);
            _enterPasscodeInfoLabel.hidden = YES;
            _optionsButton.hidden = YES;
        }
        else if (_isUserChangingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.reenterNewPasscodeString);
            _enterPasscodeInfoLabel.hidden = YES;
            _optionsButton.hidden = YES;
        }
    }
    else if (_isUserBeingAskedForNewPasscode) {
        if (_isUserEnablingPasscode || _isUserChangingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.enterNewPasscodeString);
            _enterPasscodeInfoLabel.hidden = YES; //hidden for changing PIN
            _optionsButton.hidden = NO;
        }
    }
    else {
        if (_isUserChangingPasscode) {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.enterOldPasscodeString);
            _enterPasscodeInfoLabel.hidden = YES;
            _optionsButton.hidden = YES;
        } else {
            _enterPasscodeLabel.text = LTHPasscodeViewControllerStrings(self.enterPasscodeString);
            //hidden for enabling PIN
            _enterPasscodeInfoLabel.hidden = !(_isUserEnablingPasscode && _displayAdditionalInfoDuringSettingPasscode);
            _optionsButton.hidden = !_isUserEnablingPasscode;
        }
    }
    
    _enterPasscodeInfoLabel.text = LTHPasscodeViewControllerStrings(self.enterPasscodeInfoString);
    
    // Make sure nav bar for logout is off the screen
    if (_isUsingNavBar) {
        [self.navBar removeFromSuperview];
        self.navBar = nil;
    }
    _isUsingNavBar = NO;
}


- (void)_resetUIForReEnteringNewPasscode {
    [self _resetTextFields];
    _passcodeTextField.text = @"";
    // If there's no passcode saved in Keychain,
    // the user is adding one for the first time, otherwise he's changing his passcode.
    NSString *savedPasscode = [LTHKeychainUtils getPasswordForUsername: _keychainPasscodeUsername
                                                        andServiceName: _keychainServiceName
                                                                 error: nil];
    _enterPasscodeLabel.text = savedPasscode.length == 0
    ? LTHPasscodeViewControllerStrings(self.enterPasscodeString)
    : LTHPasscodeViewControllerStrings(self.enterNewPasscodeString);
    _failedAttemptLabel.hidden = NO;
    _failedAttemptLabel.text = _newPasscodeEqualsOldPasscode
    ? LTHPasscodeViewControllerStrings(@"Cannot reuse the same passcode")
    : LTHPasscodeViewControllerStrings(@"Passcodes did not match. Try again.");
    _newPasscodeEqualsOldPasscode = NO;
    _failedAttemptLabel.backgroundColor = [UIColor clearColor];
    _failedAttemptLabel.layer.borderWidth = 0;
    _failedAttemptLabel.layer.borderColor = [UIColor clearColor].CGColor;
    _failedAttemptLabel.textColor = UIColor.mnz_redError;
    _eraseLocalDataLabel.hidden = YES;
    _optionsButton.hidden = NO;
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
    return (_isUserSwitchingBetweenPasscodeModes &&
            (_isUserBeingAskedForNewPasscode || _isUserConfirmingPasscode)) == !_isSimple;
}


- (void)optionsCodeButtonTapped:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertActionStyle style = UIAlertActionStyleDefault;
    
    __weak typeof(self) weakSelf = self;
    
    NSArray *types = @[@(PasscodeTypeFourDigits),
                       @(PasscodeTypeSixDigits),
                       @(PasscodeTypeCustomAlphanumeric)
    ];
    
    
    NSArray *titles = @[NSLocalizedString(@"4-Digit Numeric Code", @"Action text to change to 4-Digit Numeric passcode type."),
                        NSLocalizedString(@"6-Digit Numeric Code", @""),
                        NSLocalizedString(@"Custom Alphanumeric Code", @"")];
    
    // Set current passcodeType based on current displayed passcode input area, to determin action options
    if (_passcodeTextField.hidden) {
        _passcodeType = (_digitTextFieldsArray.count == 4) ? PasscodeTypeFourDigits : PasscodeTypeSixDigits;
    } else {
        _passcodeType = PasscodeTypeCustomAlphanumeric;
    }
    
    // Add all the buttons
    for (NSInteger i = 0; i < types.count; i++) {
        PasscodeType type = [types[i] integerValue];
        if (type == _passcodeType) { continue; }
        
        id handler = ^(UIAlertAction *action) {
            [weakSelf setPasscodeTypeAndInputArea:type];
        };
        UIAlertAction* action = [UIAlertAction actionWithTitle:titles[i] style:style handler:handler];
        [alertController addAction:action];
    }
    
    // Cancel button
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];
    
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    alertController.popoverPresentationController.sourceView = self.optionsButton;
    alertController.popoverPresentationController.sourceRect = self.optionsButton.bounds;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp;
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Notification Observers
- (void)_applicationDidEnterBackground {
    if ([self _passcode].length != 0) {
        if ([_passcodeTextField isFirstResponder]) {
            _useFallbackPasscode = NO;
            [_passcodeTextField resignFirstResponder];
        }
        
        if (_isCurrentlyOnScreen && !_displayedAsModal) return;
        
        _coverView.hidden = NO;
        if (![[UIApplication currentWindow] viewWithTag: _coverViewTag]) {
            [[UIApplication currentWindow] addSubview: _coverView];
        }
    }
}


- (void)_applicationDidBecomeActive {
    // If we are not being displayed as lockscreen, it means the biometrics alert
    // just closed - it also calls UIApplicationDidBecomeActiveNotification
    // and if we open for changing / turning off really fast, it will call this
    // after viewWillAppear, and it will hide the UI.
    if (_isUsingBiometrics && !_useFallbackPasscode && _displayedAsLockScreen) {
        _animatingView.hidden = YES;
        [_passcodeTextField resignFirstResponder];
    }
    _coverView.hidden = YES;
}


- (void)_applicationWillEnterForeground {
    if ([self _passcode].length != 0 &&
        [self _didPasscodeTimerEnd]) {
        _useFallbackPasscode = NO;
        
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
                                   withLogout:YES
                               andLogoutTitle:NSLocalizedString(@"logoutLabel", nil)];
        }
    }
}


- (void)_applicationWillResignActive {
    if ([self _passcode].length != 0 && !([self isCurrentlyOnScreen] && [self displayedAsLockScreen])) {
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
    _digitsCount = LTHMinPasscodeDigits;
    _digitTextFieldsArray = [NSMutableArray new];
    _coverViewTag = 994499;
    _lockAnimationDuration = 0.25;
    _slideAnimationDuration = 0.15;
    _maxNumberOfAllowedFailedAttempts = 0;
    _usesKeychain = YES;
    _isSimple = YES;
    _passcodeType = PasscodeTypeFourDigits;
    _displayedAsModal = YES;
    _hidesBackButton = YES;
    _hidesCancelButton = YES;
    _passcodeAlreadyExists = YES;
    _newPasscodeEqualsOldPasscode = NO;
    _allowUnlockWithBiometrics = [self _allowUnlockWithBiometrics];
    _passcodeCharacter = @"\u2014"; // A longer "-";
    _localizationTableName = @"LTHPasscodeViewController";
    _displayAdditionalInfoDuringSettingPasscode = NO;
}


- (void)_loadStringDefaults {
    self.enterOldPasscodeString = @"Enter your old passcode";
    self.enterPasscodeString = @"Enter your passcode";
    self.enterPasscodeInfoString = @"Passcode info";
    self.enablePasscodeString = @"Enable Passcode";
    self.changePasscodeString = @"Change Passcode";
    self.turnOffPasscodeString = @"Turn off passcode";
    self.reenterPasscodeString = @"Re-enter your passcode";
    self.reenterNewPasscodeString = @"Re-enter your new passcode";
    self.enterNewPasscodeString = @"Enter your new passcode";
    self.biometricsDetailsString = @"Unlock using Touch ID";
}


- (void)_loadGapDefaults {
    _fontSizeModifier = LTHiPad ? 1.5 : 1;
    _horizontalGap = 40 * _fontSizeModifier;
    _verticalGap = LTHiPad ? 50.0f : 25.0f;
    _modifierForBottomVerticalGap = LTHiPad ? 2.6f : 3.0f;
    _failedAttemptLabelGap = _verticalGap * _modifierForBottomVerticalGap - 2.0f;
    _passcodeOverlayHeight = LTHiPad ? 96.0f : 40.0f;
}


- (void)_loadFontDefaults {
    _labelFontSize = 15.0;
    _passcodeFontSize = 33.0;
    _optionsButtonFontSize = 16.0;
    _labelFont = [UIFont fontWithName: @"AvenirNext-Regular"
                                 size: _labelFontSize * _fontSizeModifier];
    _passcodeFont = [UIFont fontWithName: @"AvenirNext-Regular"
                                    size: _passcodeFontSize * _fontSizeModifier];
    _optionsButtonFont = [UIFont systemFontOfSize:_optionsButtonFontSize * _fontSizeModifier weight:UIFontWeightMedium];
}


- (void)_loadColorDefaults {
    // Backgrounds
    _backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    _passcodeBackgroundColor = [UIColor clearColor];
    _coverViewBackgroundColor = UIColor.mnz_background;
    _failedAttemptLabelBackgroundColor =  UIColor.mnz_redError;
    _enterPasscodeLabelBackgroundColor = [UIColor clearColor];
    _eraseLocalDataLabelBackgroundColor = [UIColor clearColor];
    
    // Text
    _labelTextColor = UIColor.mnz_label;
    _passcodeTextColor = UIColor.mnz_label;
    _failedAttemptLabelTextColor = UIColor.mnz_background;
    _eraseLocalDataLabelTextColor = UIColor.mnz_redError;
    _optionsButtonTextColor = [UIColor colorWithRed:0 green:168.0/255.0 blue:134.0/255.0 alpha:1.0];
    _textFieldBorderColor = [UIColor colorWithRed:60.0/255.0 green:60.0/255.0 blue:67.0/255.0 alpha:0.3];
}


- (void)_loadKeychainDefaults {
    _keychainPasscodeUsername = @"demoPasscode";
    _keychainTimerStartUsername = @"demoPasscodeTimerStart";
    _keychainServiceName = @"demoServiceName";
    _keychainTimerDurationUsername = @"passcodeTimerDuration";
    _keychainPasscodeIsSimpleUsername = @"passcodeIsSimple";
    _keychainPasscodeTypeUsername = @"passcodeType";
    _keychainAllowUnlockWithBiometrics = @"allowUnlockWithTouchID";
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
    _animatingView.frame = self.view.bounds;
}


// And to his AGWindowView: https://github.com/hfossli/AGWindowView
// Without the 'desiredOrientation' method, using showLockscreen in one orientation,
// then presenting it inside a modal in another orientation would display
// the view in the first orientation.
- (UIInterfaceOrientation)desiredOrientation {
    UIInterfaceOrientation statusBarOrientation = CGRectGetWidth(UIScreen.mainScreen.bounds) < CGRectGetHeight(UIScreen.mainScreen.bounds) ? UIInterfaceOrientationPortrait : UIInterfaceOrientationLandscapeLeft;
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
    
    [self setIfNotEqualTransform: transform];
}


- (void)setIfNotEqualTransform:(CGAffineTransform)transform {
    CGRect frame = self.view.superview.frame;
    if(!CGAffineTransformEqualToTransform(self.view.transform, transform)) {
        self.view.transform = transform;
    }
    if(!CGRectEqualToRect(self.view.frame, frame)) {
        self.view.frame = frame;
    }
}

- (void)disablePasscodeWhenApplicationEntersBackground {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIApplicationDidEnterBackgroundNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIApplicationWillEnterForegroundNotification
     object:nil];
}

- (void)enablePasscodeWhenApplicationEntersBackground {
    // To avoid double registering.
    [self disablePasscodeWhenApplicationEntersBackground];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_applicationDidEnterBackground)
     name:UIApplicationDidEnterBackgroundNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_applicationWillEnterForeground)
     name:UIApplicationWillEnterForegroundNotification
     object:nil];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){}
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        [self calculateOffsetGap];
        self.enterPasscodeConstraintCenterY.constant = self.yOffsetFromCenter;
        self.optionsButtonConstraintTop.constant = [self calculateOptionsButtonTopGap];
    }];
}

@end
