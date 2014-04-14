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
- (void)passcodeViewControllerWasDismissed;
- (void)maxNumberOfFailedAttemptsReached;
- (void)passcodeWasEnteredSuccessfully;
- (void)logoutButtonWasPressed;
@end

@interface LTHPasscodeViewController : UIViewController

@property (nonatomic, weak) UIViewController<LTHPasscodeViewControllerDelegate> *delegate;

// Customization
@property (nonatomic, strong) UIColor *navigationBarTintColor;
@property (nonatomic, strong) UIColor *navigationTintColor;
@property (nonatomic, strong) UIColor *navigationTitleColor;
@property (nonatomic, assign) BOOL navigationBarTranslucent;
@property (nonatomic, strong) UINavigationBar *navBar;

// Used when displaying the lock. Shown without a navBar, added directly on UIWindow
- (void)showLockScreenWithAnimation:(BOOL)animated;
/**
 *  Used when displaying the lock. Added directly on UIWindow
 *
 *  @param hasLogout   Show a logout button. If set to YES, a navBar will be shown, if set to NO, no navBar will be shown
 *  @param logoutTitle Logout button's title.
 */
- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle;
/**
 *  Used when enabling/changing/disabling the passcode.
 *
 *  @param viewController Shown as a modal, with navBar.
 */
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController;

/**
 *  These should have been private, but since I didn't do that from the start,
 *  consider them helper methods, should they serve you in any way. 
 *  I don't want to break backwards compatibility.
 */
- (void)prepareAsLockScreen;
- (void)prepareForChangingPasscode;
- (void)prepareForTurningOffPasscode;
- (void)prepareForEnablingPasscode;
- (void)dismissMe;
- (void)resetUI;
/**
 *  @return YES if the passcode is simple (4 digits),
 *	NO if the passcode is complex
 */
- (BOOL)isSimple;
- (void)setIsSimple:(BOOL)isSimple;
/**
 *  Saves the passcode in the keychain, with the following data:
 *
 *  @param username    Username used for storing the passcode.
 *  @param serviceName Service name used for storing the passcode.
 */
+ (void)setUsername:(NSString*)username andServiceName:(NSString*)serviceName;
/**
 *  @return YES if the passcode is enabled.
 */
+ (BOOL)passcodeExistsInKeychain;
/**
 *  Saves in the keychain the time that needs to pass for the lock to be displayed.
 *
 *  @param duration The time that needs to pass for the lock to be displayed.
 */
+ (void)setTimerDuration:(NSTimeInterval)duration;
/**
 *  Retrieves from the keychain the time that needs to pass for the lock to be displayed.
 *  @return The time that needs to pass for the lock to be displayed.
 */
+ (NSTimeInterval)timerDuration;
/**
 *  @return YES if the timer ended and the lock has to be displayed.
 */
+ (BOOL)didPasscodeTimerEnd;
/**
 *  Saves current time, as `timeIntervalSinceReferenceDate`.
 */
+ (void)saveTimerStartTime;
/**
 *  Retrieves from the keychain the time at which the timer started.
 *
 *  @return The time, as `timeIntervalSinceReferenceDate`, at which the timer started.
 */
+ (NSTimeInterval)timerStartTime;
/**
 *  Removes the passcode from the keychain.
 */
+ (void)deletePasscodeFromKeychain;
+ (LTHPasscodeViewController *)sharedUser;

@end