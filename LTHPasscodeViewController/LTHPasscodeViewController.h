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
 @brief Called right before the passcode view controller will be dismissed or popped.
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
 @brief	  Handle here the retrieval of the duration that needs to pass while app is in background for the lock to be displayed.
 @details Called when @c +timerDuration is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return The duration.
 */
- (NSTimeInterval)timerDuration;
/**
 @brief			 Handle here the saving of the duration that needs to pass while the app is in background for the lock to be displayed.
 @details        Called when @c +saveTimerDuration: is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @param duration The duration.
 */
- (void)saveTimerDuration:(NSTimeInterval)duration;
/**
 @brief   Handle here the retrieval of the time at which the timer started.
 @details Called when @c +timerStartTime is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return The time at which the timer started.
 */
- (NSTimeInterval)timerStartTime;
/**
 @brief    Handle here the saving of the current time.
 @details  Called when @c +saveTimerStartTime is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 */
- (void)saveTimerStartTime;
/**
 @brief      Handle here the check if the timer has ended and the lock has to be displayed.
 @details    Called when @c +didPasscodeTimerEnd is called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return @c YES if the timer ended and the lock has to be displayed.
 */
- (BOOL)didPasscodeTimerEnd;
/**
 @brief   Handle here the passcode deletion.
 @details Called when @c +deletePasscode or @c +deletePasscodeAndClose are called and @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 */
- (void)deletePasscode;
/**
 @brief   Handle here the saving of the passcode.
 @details Called if @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @param passcode The passcode.
 */
- (void)savePasscode:(NSString *)passcode;
/**
 @brief   Retrieve here the saved passcode.
 @details Called if @c +useKeychain:NO was used, but falls back to the Keychain anyway if not implemented.
 @return The passcode.
 */
- (NSString *)passcode;
@end

@interface LTHPasscodeViewController : UIViewController
/**
 @brief   The delegate.
 */
@property (nonatomic, weak) id<LTHPasscodeViewControllerDelegate> delegate;
/**
 @brief The gap between the passcode digits.
 */
@property (nonatomic, assign) CGFloat   horizontalGap;
/**
 @brief The gap between the top label and the passcode digits/field.
 */
@property (nonatomic, assign) CGFloat   verticalGap;
/**
 @brief The offset between the top label and middle position.
 */
@property (nonatomic, assign) CGFloat   verticalOffset;
/**
 @brief The gap between the passcode digits and the failed label.
 */
@property (nonatomic, assign) CGFloat   failedAttemptLabelGap;
/**
 @brief The height for the complex passcode overlay.
 */
@property (nonatomic, assign) CGFloat   passcodeOverlayHeight;
/**
 @brief The font size for the top label.
 */
@property (nonatomic, assign) CGFloat   labelFontSize;
/**
 @brief The font size for the passcode digits.
 */
@property (nonatomic, assign) CGFloat   passcodeFontSize;
/**
 @brief The font for the top label.
 */
@property (nonatomic, strong) UIFont    *labelFont;
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
 @brief The background image for the coverview.
 */
@property (nonatomic, strong) UIImage   *backgroundImage;
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
 @brief The string displayed when entering your old passcode (while changing).
 */
@property (nonatomic, strong) NSString *enterOldPasscodeString;
/**
 @brief The string displayed when entering your passcode.
 */
@property (nonatomic, strong) NSString *enterPasscodeString;
/**
 @brief The string displayed when entering your new passcode (while changing).
 */
@property (nonatomic, strong) NSString *enterNewPasscodeString;
/**
 @brief The string displayed when enabling your passcode.
 */
@property (nonatomic, strong) NSString *enablePasscodeString;
/**
 @brief The string displayed when changing your passcode.
 */
@property (nonatomic, strong) NSString *changePasscodeString;
/**
 @brief The string displayed when disabling your passcode.
 */
@property (nonatomic, strong) NSString *turnOffPasscodeString;
/**
 @brief The string displayed when reentering your passcode.
 */
@property (nonatomic, strong) NSString *reenterPasscodeString;
/**
 @brief The string displayed when reentering your new passcode (while changing).
 */
@property (nonatomic, strong) NSString *reenterNewPasscodeString;
/**
 @brief The string displayed while user unlocks with Touch ID.
 */
@property (nonatomic, strong) NSString *touchIDString;
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
 @brief A Boolean value that indicates whether the navigation bar is translucent (@c YES) or not (@c NO).
 */
@property (nonatomic, assign) BOOL navigationBarTranslucent;
/**
 @brief A Boolean value that indicates whether the back bar button is hidden (@c YES) or not (@c NO). Default is @c YES.
 */
@property (nonatomic, assign) BOOL hidesBackButton;
/**
 @brief A Boolean value that indicates whether Touch ID can be used (@c YES) or not (@c NO). Default is @c YES.
 */
@property (nonatomic, assign) BOOL allowUnlockWithTouchID;

/**
 @brief				Used for displaying the lock. The passcode view is added directly on the keyWindow.
 @param hasLogout   Set to @c YES for a navBar with a Logout button, set to @c NO for no navBar.
 @param logoutTitle The title of the Logout button.
 */
- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle;
/**
 @brief				   Used for enabling the passcode.
 @details              The back bar button is hidden by default. Set @c hidesBackButton to @c NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 */
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief				   Used for changing the passcode.
 @details              The back bar button is hidden by default. Set @c hidesBackButton to @c NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 */
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief				   Used for disabling the passcode.
 @details              The back bar button is hidden by default. Set @c hidesBackButton to @c NO if you want it to be visible.
 @param	viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 */
- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief  Returns a Boolean value that indicates whether a simple, 4 digit (@c YES) or a complex passcode will be used (@c NO).
 @return @c YES if the passcode is simple, @c NO if the passcode is complex
 */
- (BOOL)isSimple;
/**
 @brief                 Sets if the passcode should be simple (4 digits) or complex.
 @param isSimple        Set to @c YES for a simple passcode, and to @c NO for a complex passcode.
 @param viewController  The view controller where the passcode view controller will be displayed.
 @param isModal         Set to @c YES to present as a modal, or to @c NO to push on the current nav stack.
 @details               @c inViewController and @c asModal are needed because the delegate is of type id, and the passcode needs to be presented somewhere and with a specific style - modal or pushed.
 */
- (void)setIsSimple:(BOOL)isSimple inViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
/**
 @brief  Returns a Boolean value that indicates whether a passcode exists (@c YES) or not (@c NO).
 @return @c YES if a passcode is enabled. This also means it is enabled, unless custom logic was added to the library.
 */
+ (BOOL)doesPasscodeExist;
/**
 @brief	 Retrieves from the keychain the duration while app is in background after which the lock has to be displayed.
 @return The duration.
 */
+ (NSTimeInterval)timerDuration;
/**
 @brief			 Saves in the keychain the duration that needs to pass while app is in background  for the lock to be displayed.
 @param duration The duration.
 */
+ (void)saveTimerDuration:(NSTimeInterval)duration;
/**
 @brief  Retrieves from the keychain the time at which the timer started.
 @return The time, as @c timeIntervalSinceReferenceDate, at which the timer started.
 */
+ (NSTimeInterval)timerStartTime;
/**
 @brief Saves the current time, as @c timeIntervalSinceReferenceDate.
 */
+ (void)saveTimerStartTime;
/**
 @brief  Returns a Boolean value that indicates whether the timer has ended (@c YES) and the lock has to be displayed or not (@c NO).
 @return @c YES if the timer ended and the lock has to be displayed.
 */
+ (BOOL)didPasscodeTimerEnd;
/**
 @brief Removes the passcode from the keychain.
 */
+ (void)deletePasscode;
/**
 @brief Closes the passcode view controller.
 */
+ (void)close;
/**
 @brief Removes the passcode from the keychain and closes the passcode view controller.
 */
+ (void)deletePasscodeAndClose;
/**
 @brief             Call this if you want to save and read the passcode and timers to and from somewhere else rather than the Keychain.
 @attention         All the protocol methods will fall back to the Keychain if not implemented, even if calling this method with @c NO. This allows for flexibility over what and where you save.
 @param useKeychain Set to @c NO if you want to save and read the passcode and timers to and from somewhere else rather than the Keychain. Default is @c YES.
 */
+ (void)useKeychain:(BOOL)useKeychain;
/**
 @brief  Returns the shared instance of the passcode view controller.
 */
+ (instancetype)sharedUser;

@end