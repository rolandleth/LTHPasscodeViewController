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
/**
 @brief Called when the passcode controller was dismissed.
 */
- (void)passcodeViewControllerWasDismissed DEPRECATED_MSG_ATTRIBUTE(" Please use passcodeViewControllerWillBeClosed. It is a better name, since it is called right before dismissing or popping the passcode view controller.");
/**
 @brief Called right before the passcode controller will be dismissed or popped.
 */
- (void)passcodeViewControllerWillClose;
/**
 @brief Called when the max number of failed attempts has been reached.
 */
- (void)maxNumberOfFailedAttemptsReached;
/**
 @brief Called when the passcode was entered successfully.
 */
- (void)passcodeWasEnteredSuccessfully;
/**
 @brief Called when the logout button was pressed.
 */
- (void)logoutButtonWasPressed;
/**
 @brief      Handle here the check if the timer has ended and the lock has to be displayed.
 @details    Called when [LTHPasscodeViewController didPasscodeTimerEnd] is called and [LTHPasscodeViewController useKeychain:NO] was used, but falls back to the Keychain anyway if not implemented.
 @return YES if the timer ended and the lock has to be displayed.
 */
- (BOOL)didPasscodeTimerEnd;
/**
 @brief   Handle here the passcode deletion.
 @details Called when [LTHPasscodeViewController deletePasscode] is called and [LTHPasscodeViewController useKeychain:NO] was used, but falls back to the Keychain anyway if not implemented.
 */
- (void)deletePasscode;
/**
 @brief   Handle here the saving of the passcode.
 @details Called if [LTHPasscodeViewController useKeychain:NO] was used, but falls back to the Keychain anyway if not implemented.
 @param passcode The passcode.
 */
- (void)savePasscode:(NSString *)passcode;
/**
 @brief   Retrieve here the saved passcode.
 @details Called if [LTHPasscodeViewController useKeychain:NO] was used, but falls back to the Keychain anyway if not implemented.
 @return The passcode.
 */
- (NSString *)passcode;
/**
 @brief   "I Forgot My Password" tapped
 @details Called if "I Forgot My Password" button was tappeg.
 */
- (void)iWishIRememberedMyPasscode;
@end

@interface LTHPasscodeViewController : UIViewController
/**
 @brief   The delegate.
 */
@property (nonatomic, weak) id<LTHPasscodeViewControllerDelegate> delegate;
/**
 @brief The font size for the top label.
 */
@property (nonatomic, assign) CGFloat   labelFontSize;
/**
 @brief The font size for the failed attempt label.
 */
@property (nonatomic, assign) CGFloat   failedAttemptLabelFontSize;
/**
 @brief The font size for the passcode digits.
 */
@property (nonatomic, assign) CGFloat   passcodeFontSize;
/**
 @brief The font for the top label.
 */
@property (nonatomic, strong) UIFont    *labelFont;
/**
 @brief The font for the failed attempt label.
 */
@property (nonatomic, strong) UIFont    *failedAttemptLabelFont;
/**
 @brief The font for the passcode digits.
 */
@property (nonatomic, strong) UIFont    *passcodeFont;
/**
 @brief The background color for the top label.
 */
@property (nonatomic, strong) UIColor   *enterPasscodeLabelBackgroundColor;
/**
 @brief The background color for the view.
 */
@property (nonatomic, strong) UIColor   *backgroundColor;
/**
 @brief The background color for the cover view that appears on top of the app, visible in the multitasking.
 */
@property (nonatomic, strong) UIColor   *coverViewBackgroundColor;
/**
 @brief The background color for the passcode digits.
 */
@property (nonatomic, strong) UIColor   *passcodeBackgroundColor;
/**
 @brief The background color for the failed attempt label.
 */
@property (nonatomic, strong) UIColor   *failedAttemptLabelBackgroundColor;
/**
 @brief The text color for the top label.
 */
@property (nonatomic, strong) UIColor   *labelTextColor;
/**
 @brief The text color for the passcode digits.
 */
@property (nonatomic, strong) UIColor   *passcodeTextColor;
/**
 @brief The text color for the failed attempt label.
 */
@property (nonatomic, strong) UIColor   *failedAttemptLabelTextColor;
/**
 @brief The tint color to apply to the navigation items and bar button items.
 */
@property (nonatomic, strong) UIColor   *navigationBarTintColor;
/**
 @brief The tint color to apply to the navigation bar background.
 */
@property (nonatomic, strong) UIColor   *navigationTintColor;
/**
 @brief The color for te navigation bar's title.
 */
@property (nonatomic, strong) UIColor   *navigationTitleColor;
/**
 @brief The string to be used as username for the passcode in the Keychain.
 */
@property (nonatomic, strong) NSString  *keychainPasscodeUsername;
/**
 @brief The string to be used as username for the timer start time in the Keychain.
 */
@property (nonatomic, strong) NSString  *keychainTimerStartUsername;
/**
 @brief The string to be used as username for the timer duration in the Keychain.
 */
@property (nonatomic, strong) NSString  *keychainTimerDurationUsername;
/**
 @brief The string to be used as service name for all the Keychain entries.
 */
@property (nonatomic, strong) NSString  *keychainServiceName;
/**
 @brief The character for the passcode digit.
 */
@property (nonatomic, strong) NSString  *passcodeCharacter;
/**
 @brief The table name for NSLocalizedStringFromTable.
 */
@property (nonatomic, strong) NSString  *localizationTableName;
/**
 @brief The tag for the cover view.
 */
@property (nonatomic, assign) NSInteger coverViewTag;
/**
 @brief The duration of the lock animation.
 */
@property (nonatomic, assign) CGFloat   lockAnimationDuration;
/**
 @brief The duration of the slide animation.
 */
@property (nonatomic, assign) CGFloat   slideAnimationDuration;
/**
 @brief The maximum number of failed attempts allowed.
 */
@property (nonatomic, assign) NSInteger maxNumberOfAllowedFailedAttempts;
/**
 @brief The navigation bar, if one was used.
 */
@property (nonatomic, strong) UINavigationBar *navBar;
/**
 @brief A Boolean value that indicates whether the navigation bar is translucent (YES) or not (NO).
 */
@property (nonatomic, assign) BOOL navigationBarTranslucent;
/**
 @brief A Boolean value that indicates whether the back bar button is hidden (YES) or not (NO). Default is YES.
 */
@property (nonatomic, assign) BOOL hidesBackButton;
/**
 @brief A Boolean value that indicates whether the view controller is currently on screen.
 */
@property (nonatomic, assign) BOOL isCurrentlyOnScreen;

/**
 @brief				Used for displaying the lock. The passcode view is added directly on the keyWindow.
 @param hasLogout   Set to YES for a navBar with a Logout button, set to NO for no navBar.
 @param logoutTitle The title of the Logout button.
 */
- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle;
/**
 @brief   Used for displaying the lock. Added directly on UIWindow.
 */
- (void)showLockScreenWithAnimation:(BOOL)animated DEPRECATED_MSG_ATTRIBUTE(" Please use showLockScreenWithAnimation:withLogout:andLogoutTitle:");
/**
 @brief				   Used for enabling the passcode.
 @details              The back bar button is hidden by default. Set `hidesBackButton` to NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 */
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController DEPRECATED_MSG_ATTRIBUTE(" Please use showForEnablingPasscodeInViewController:asModal:");
/**
 @brief				   Used for changing the passcode.
 @details              The back bar button is hidden by default. Set `hidesBackButton` to NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 */
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController DEPRECATED_MSG_ATTRIBUTE(" Please use showForDisablingPasscodeInViewController:asModal:");
/**
 @brief				   Used for disabling the passcode.
 @details              The back bar button is hidden by default. Set `hidesBackButton` to NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 */
- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController DEPRECATED_MSG_ATTRIBUTE(" Please use showForDisablingPasscodeInViewController:asModal:");
/**
 @brief				   Used for enabling the passcode.
 @details              The back bar button is hidden by default. Set `hidesBackButton` to NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to YES to present as a modal, or to NO to push on the current nav stack.
 */
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief				   Used for changing the passcode.
 @details              The back bar button is hidden by default. Set `hidesBackButton` to NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to YES to present as a modal, or to NO to push on the current nav stack.
 */
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief				   Used for disabling the passcode.
 @details              The back bar button is hidden by default. Set `hidesBackButton` to NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to YES to present as a modal, or to NO to push on the current nav stack.
 */
- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief  Returns a Boolean value that indicates whether a simple, 4 digit (YES) or a complex passcode will be used (NO).
 @return YES if the passcode is simple, NO if the passcode is complex
 */
- (BOOL)isSimple;
/**
 @brief   Starting with next version, this will be just a setter, without the current logic inside. Everything was moved inside `-setIsSimple:inViewController:asModal:`
 @details `fromParentViewController` and `asModal` are needed because the delegate is of type id, and the passcode needs to be presented somewhere and with a specific style - modal or pushed.
 */
- (void)setIsSimple:(BOOL)isSimple DEPRECATED_MSG_ATTRIBUTE(" Please use -setIsSimple:inViewController:asModal:");
/**
 @brief                 Sets if the passcode should be simple (4 digits) or complex.
 @param isSimple        Set to YES for a simple passcode, and to NO for a complex passcode.
 @param viewController  The view controller where the passcode view controller will be displayed.
 @param isModal         Set to YES to present as a modal, or to NO to push on the current nav stack.
 */
- (void)setIsSimple:(BOOL)isSimple inViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief   Returns a Boolean value that indicates whether a passcode exists (YES) or not (NO).
 @return  YES if a passcode is enabled. This also means it is enabled, unless custom logic was added to the library.
 */
+ (BOOL)passcodeExistsInKeychain DEPRECATED_MSG_ATTRIBUTE(" Please use -doesPasscodeExist");
/**
 @brief  Returns a Boolean value that indicates whether a passcode exists (YES) or not (NO).
 @return YES if a passcode is enabled. This also means it is enabled, unless custom logic was added to the library.
 */
+ (BOOL)doesPasscodeExist;
/**
 @brief Removes the passcode from the keychain.
 */
+ (void)deletePasscodeFromKeychain DEPRECATED_MSG_ATTRIBUTE(" Please use -deleteFromPasscode");
/**
 @brief Removes the passcode from the keychain.
 */
+ (void)deletePasscode;
/**
 @brief             Call this if you want to save and read the passcode and timers to and from somewhere else rather than the Keychain.
 @attention         All the protocol methods will fall back to the Keychain if not implemented, even if calling this method with NO. This allows for flexibility over what and where you save.
 @param useKeychain Set to NO if you want to save and read the passcode and timers to and from somewhere else rather than the Keychain. Default is YES.
 */
+ (void)useKeychain:(BOOL)useKeychain;
/**
 @brief  Returns the shared instance of the passcode view controller.
 */
+ (instancetype)sharedUser;

- (void)addClueLogo;

@end