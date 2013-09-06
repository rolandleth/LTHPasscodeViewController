//
//  PasscodeViewController.h
//  ExpensesPlanner
//
//  Created by Roland Leth on 9/4/13.
//  Copyright (c) 2013 Roland Leth. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol LTHPasscodeViewControllerDelegate;
@interface LTHPasscodeViewController : UIViewController <UITextFieldDelegate> {
	UIView *_animatingView;
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
	BOOL _beingDisplayedAsLockscreen;
	NSString *_tempPasscode;
}


@property (nonatomic, weak) id<LTHPasscodeViewControllerDelegate> delegate;
@property (assign) BOOL isCurrentlyOnScreen;


- (id)initForTurningPasscodeOff;
- (id)initForChangingPasscode;
- (id)initForBeingDisplayedAsLockscreen;
+ (BOOL)passcodeExistsInKeychain;


@end


// These serve, mostly, as an "update stuff after dismissing"
@protocol LTHPasscodeViewControllerDelegate <NSObject>
@optional
- (void)passcodeViewControllerWasDismissed;
- (void)refreshUI;
@end