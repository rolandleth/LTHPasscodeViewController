# LTHPasscodeViewController
Simple to use iOS 7 style Passcode - the one you get in Settings when changing your passcode.

# Installation

### Swift Package Manager

__NOTE__: _These instructions are intended for usage on Xcode 11 and higher. Xcode 11 is the first version of Xcode that integrates Swift Package manager and makes it way easier to use than it was at the command line. If you are using older versions of Xcode, we recommend using CocoaPods._

1. Go to `File > Swift Packages > Add Package Dependency...` or directly to `File > Add Package Dependency...`
2. Paste the URL to the `LTHPasscodeViewController` repo on GitHub (https://github.com/rolandleth/LTHPasscodeViewController.git) into the search bar, then hit the Next button:
3. Select what version you want to use, then hit next (Xcode will automatically suggest the current version Up to Next Major).
4. Select the `LTHPasscodeViewController` library and then hit finish.
5. You're done!

### CocoaPods

__NOTE__: As per [this post](https://blog.cocoapods.org/CocoaPods-Specs-Repo/), it seems CocoaPods will sunset in the not-too-far future. I will leave this here for a while, but 4.0.1 is the last version to be added to CocoaPods and I will be exclusively using SPM moving forward. 

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `LTHPasscodeViewController` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'LTHPasscodeViewController', '~> 4.0.1'
```

### Manually

Simply clone the repo and drag the contents of `LTHPasscodeViewController` to your project.

# How to use

If your app uses extensions, `LTH_IS_APP_EXTENSION` needs to be defined:

* either in each target's `Prefix.pch` file, if there is one, via `#define LTH_IS_APP_EXTENSION`
* or in each target's build settings, down to `Preprocessor Macros`, double click each of your schemes, click on the `+` on the popup that appears and add `LTH_IS_APP_EXTENSION`

Example, called in `application:didFinishLaunchingWithOptions`:

```objc
[LTHPasscodeViewController useKeychain:NO];
if ([LTHPasscodeViewController doesPasscodeExist]) {
    if ([LTHPasscodeViewController didPasscodeTimerEnd])
        [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES
                                                                 withLogout:NO
                                                             andLogoutTitle:nil];
}
```

* Supports simple (4 digit) and complex passcodes.
* Supports Touch ID and Face ID. If you're using Face ID, be sure to add `NSFaceIDUsageDescription` to your `Info.plist`. Documentation can be found here: https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW75 (Thanks [@mgod](https://github.com/mgod) for the suggestion made in [#193](https://github.com/rolandleth/LTHPasscodeViewController/issues/193)).
* Data us saved in the Keychain, by default. Supports custom saving, by calling `[LTHPasscodeViewController useKeychain:NO]` after initializing and implementing a few protocol methods (the same names the library uses for the same job):

```objc
- (void)passcodeViewControllerWillClose;
- (void)maxNumberOfFailedAttemptsReached;
- (void)passcodeWasEnteredSuccessfully;
- (void)logoutButtonWasPressed;
- (NSTimeInterval)timerDuration;
- (void)saveTimerDuration:(NSTimeInterval)duration;
- (NSTimeInterval)timerStartTime;
- (void)saveTimerStartTime;
- (BOOL)didPasscodeTimerEnd;
- (void)deletePasscode;
- (void)savePasscode:(NSString *)passcode;
- (NSString *)passcode;
// All of them fall back on the Keychain if they are not implemented, even if [LTHPasscodeViewController useKeychain:NO] was called, for flexibility over what and where you save.
// Do you only want to save the passcode in a different location and leave everything else in the Keychain? Call [LTHPasscodeViewController useKeychain:NO], but only implement -savePasscode:
```

* Open as a modal, or pushed for changing, enabling or disabling the passcode:

```objc
/**
 @param viewController The view controller where the passcode view controller will be displayed.
 @param asModal        Set to YES to present as a modal, or to NO to push on the current nav stack.
 */
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
- (void)showForDisablingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController asModal:(BOOL)isModal;
```

* Show the lock screen over the window:

```objc
- (void)showLockScreenWithAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString*)logoutTitle;

// Example:
[[LTHPasscodeViewController sharedUser] showLockscreenWithAnimation:YES withLogout:NO andLogoutTitle:nil];
// Displayed with a slide up animation, which, combined with
// the keyboard sliding down animation, creates an "unlocking" impression.
```

* Show the lock screen over a specific view. Works like the above method, but the size and center will be of the passed in view:

```objc
- (void)showLockScreenOver:(UIView *)superview withAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString *)logoutTitle;

// Example:
[[LTHPasscodeViewController sharedUser] showLockscreenOver:popover withAnimation:YES withLogout:NO andLogoutTitle:nil];
```

* entering foreground and resigning is handled from within the class.

If you're using Storyboards and need to show the lockscreen right at launch, but it's acting weird, you could try and initialise your Storyboard by code, as suggested in [this issue](https://github.com/rolandleth/LTHPasscodeViewController/issues/172) by Ben (thank you!).

Makes use of [SFHFKeyChainUtils](https://github.com/ldandersen/scifihifi-iphone) to save the passcode in the Keychain. I know he dropped support for it, but I updated it for ARC 2 years ago ([with help](http://stackoverflow.com/questions/7663443/sfhfkeychainutils-ios-keychain-arc-compatible)) and I kept using it since. The 'new' version isn't updated to ARC anyway, so I saw no reason to switch to it, or to any other library.

Feel free to [contact me](mailto:roland@rolandleth.com), or open an issue if anything is unclear, bugged, or can be improved.

![Screenshot](https://rolandleth.com/images/ios7-style-passcode/screenshot.png)   ![Screenshot](https://rolandleth.com/images/ios7-style-passcode/change-passcode-screenshot.png)

# Apps using this control
[Expenses Planner](https://itunes.apple.com/us/app/expenses-planner-reminders/id669431471?mt=8), [DigitalOcean Manager](https://itunes.apple.com/us/app/digitalocean-manager/id633128302?mt=8), [LovelyHeroku](https://itunes.apple.com/us/app/lovelyheroku/id706287663?mt=8&uo=4), [Flow Web Browser](https://itunes.apple.com/us/app/flow-web-browser-downloader/id705536564?mt=8), [Balance - Checkbook App](https://itunes.apple.com/US/app/id854362248), [QIF Reader](https://itunes.apple.com/us/app/qif-reader/id374178932?mt=8), [Zee - Personal Finance](https://itunes.apple.com/us/app/zee-personal-finance/id422694086?mt=8), [EZDiary](https://itunes.apple.com/us/app/ezdiary-my-diary/id1128083826?ls=1&mt=8), [MEGA](https://itunes.apple.com/us/app/mega/id706857885?mt=8).

If you're using this control, I'd love hearing from you!

# License
Licensed under MIT. If you'd like (or need) a license without attribution, don't hesitate to [contact me](mailto:roland@rolandleth.com).
