# LTHPasscodeViewController
Simple to use iOS 7 style (replica, if you will) Passcode view. Not the Lock Screen one, but the one you get in Settings when changing your passcode.
I made it a singleton because if the lock is active, when leaving the app a view must be placed on top, so no data from within the app can be seen in the multitasking mode. This is done under the hood, without having to do anything extra.

# How to use
Drag the contents of `AddToYourProject` to your project, or add `pod 'LTHPasscodeViewController'` to your podspec file.

* When opened from Settings (as a modal):

```objc
- (void)showForEnablingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForChangingPasscodeInViewController:(UIViewController *)viewController;
- (void)showForTurningOffPasscodeInViewController:(UIViewController *)viewController;

// Example:
[[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController: self]
```

* At app launch, or whenever you'd like the user to be shown a passcode entry:

```objc
- (void)showLockscreen;

// Example:
[[LTHPasscodeViewController sharedUser] showLockscreen]
// Displayed with a slide up animation, which, combined with 
// the keyboard sliding down animation, creates an "unlocking" impression.
```

* entering foreground and resigning is handled from within the class. 

Everything is easily customizable with macros and static constants.

Makes use of [SFHFKeyChainUtils](https://github.com/ldandersen/scifihifi-iphone) to save the passcode in the Keychain. I know he dropped support for it, but I updated it for ARC 2 years ago ([with help](http://stackoverflow.com/questions/7663443/sfhfkeychainutils-ios-keychain-arc-compatible)) and I kept using it since. The 'new' version isn't updated to ARC anyway, so I saw no reason to switch to it, or to any other library.

Rather than writing a big documentation, I heavily commented it as best as I could. Feel free to [contact me](mailto:roland@rolandleth.com), or open an issue if anything is unclear, bugged, or can be improved. 

![Screenshot](http://rolandleth.com/assets/ios7-style-passcode/screenshot.png)   ![Screenshot](http://rolandleth.com/assets/ios7-style-passcode/change-passcode-screenshot.png)

# License
Licensed under MIT. If you'd like, or need, a license without attribution, don't hesitate to [contact me](mailto:roland@rolandleth.com).
