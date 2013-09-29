//
//  PasscodeViewController.h
//  LTHPasscodeViewController
//
//  Created by Roland Leth on 9/6/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol LTHPasscodeViewControllerDelegate;
@interface LTHPasscodeViewController : UIViewController <UITextFieldDelegate> {
	UIView *_animatingView;
	UIView *_coverView;
	UITextField *_firstDigitTextField;
	UITextField *_secondDigitTextField;
	UITextField *_thirdDigitTextField;
	UITextField *_fourthDigitTextField;
	UITextField *_passcodeTextField;
	UILabel *_failedAttemptLabel;
	UILabel *_enterPasscodeLabel;
	int _failedAttempts;
	BOOL _isUserConfirmingPasscode;
	BOOL _isUserBeingAskedForNewPasscode;
	BOOL _isUserTurningPasscodeOff;
	BOOL _isUserChangingPasscode;
	BOOL _isUserEnablingPasscode;
	BOOL _beingDisplayedAsLockscreen;
	NSString *_tempPasscode;
	BOOL _timerStartInSeconds;
}


@property (nonatomic, weak) id<LTHPasscodeViewControllerDelegate> delegate;
@property (assign) BOOL isCurrentlyOnScreen;

- (void)showLockscreen;
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController;

- (void)prepareAsLockscreen;
- (void)prepareForChangingPasscode;
- (void)prepareForTurningOffPasscode;
- (void)prepareForEnablingPasscode;

+ (BOOL)passcodeExistsInKeychain;
+ (BOOL)didPasscodeTimerEnd;
+ (void)saveTimerStartTime;
+ (CGFloat)timerDuration;
+ (CGFloat)timerStartTime;
+ (LTHPasscodeViewController *)sharedUser;


@end


// This serves, mostly, as an "update stuff after dismissing"
@protocol LTHPasscodeViewControllerDelegate <NSObject>
@optional
- (void)passcodeViewControllerWasDismissed;
@end