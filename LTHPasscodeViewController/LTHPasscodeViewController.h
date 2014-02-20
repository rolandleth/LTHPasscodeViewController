//
//  PasscodeViewController.h
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LTHPasscodeViewControllerDelegate <NSObject>
@optional
// This serves, mostly, as an "update stuff after dismissing"
- (void)passcodeViewControllerWasDismissed;
- (void)maxNumberOfFailedAttemptsReached;
- (void)passcodeWasEnteredSuccessfully;
- (void)logoutButtonWasPressed;
@end

@interface LTHPasscodeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, weak) id<LTHPasscodeViewControllerDelegate> delegate;
@property (assign) BOOL isCurrentlyOnScreen;

// Customization
@property (nonatomic, strong) UIColor *navigationBarTintColor;
@property (nonatomic, strong) UIColor *navigationTintColor;
@property (nonatomic, strong) UIColor *navigationTitleColor;
@property (nonatomic, assign) BOOL navigationBarTranslucent;
@property (nonatomic, strong) UINavigationBar *navBar;

- (void)showLockScreenWithAnimation:(BOOL)animated;
- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle;
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController;

- (void)prepareAsLockScreen;
- (void)prepareForChangingPasscode;
- (void)prepareForTurningOffPasscode;
- (void)prepareForEnablingPasscode;
- (void)dismissMe;
- (void)resetUI;

+ (void)setUsername:(NSString*)username andServiceName:(NSString*)serviceName;
+ (BOOL)passcodeExistsInKeychain;
+ (BOOL)didPasscodeTimerEnd;
+ (void)saveTimerStartTime;
+ (void)deletePasscodeFromKeychain;
+ (CGFloat)timerDuration;
+ (void)setTimerDuration:(float) duration;
+ (CGFloat)timerStartTime;
+ (LTHPasscodeViewController *)sharedUser;

@end