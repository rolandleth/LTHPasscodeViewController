Pod::Spec.new do |s|
  s.name         = "LTHPasscodeViewController"
  s.version      = "3.0.0"
  s.summary      = "iOS 7 style Passcode Lock"
  s.requires_arc = true
  s.description  = <<-DESC
                   # LTHPasscodeViewController
Simple to use iOS 7 style (replica, if you will) Passcode view. Not the Lock Screen one, but the one you get in Settings when changing your passcode.
I made it a singleton because if the lock is active, when leaving the app a view must be placed on top, so no data from within the app can be seen in the multitasking mode. This is done under the hood, without having to do anything extra.

# How to use
Drag the contents of `LTHPasscodeViewController` to your project, or add `pod 'LTHPasscodeViewController'` to your podspec file.

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
- (void)showLockscreenWithAnimation:(BOOL)animated;

// Example:
[[LTHPasscodeViewController sharedUser] showLockscreenWithAnimation: YES]
// Displayed with a slide up animation, which, combined with
// the keyboard sliding down animation, creates an "unlocking" impression.
```

* entering foreground and resigning is handled from within the class.

Everything is easily customizable with macros and static constants.

Makes use of [SFHFKeyChainUtils](https://github.com/ldandersen/scifihifi-iphone) to save the passcode in the Keychain. I know he dropped support for it, but I updated it for ARC 2 years ago ([with help](http://stackoverflow.com/questions/7663443/sfhfkeychainutils-ios-keychain-arc-compatible)) and I kept using it since. The 'new' version isn't updated to ARC anyway, so I saw no reason to switch to it, or to any other library.

Rather than writing a big documentation, I heavily commented it as best as I could. Feel free to [contact me](mailto:roland@rolandleth.com), or open an issue if anything is unclear, bugged, or can be improved.

## Removing Unused Localizations

Because the App Store automatically attempts to determine supported locales, and LTHPasscodeViewController includes localizations for the aforementioned locales, you may want to remove the `.strings` file and `.lproj` directory. You can do this most easily by having the following command run in a new Build Phase:

        $ find "$TARGET_BUILD_DIR" -maxdepth 8 -type f -name "LTHPasscodeViewController.strings" -execdir rm -r -v {} \;

# Apps using this control
[Expenses Planner](https://itunes.apple.com/us/app/expenses-planner-reminders/id669431471?mt=8)
[DigitalOcean Manager](https://itunes.apple.com/us/app/digitalocean-manager/id633128302?mt=8)
[LovelyHeroku](https://itunes.apple.com/us/app/lovelyheroku/id706287663?mt=8&uo=4)
[Flow Web Browser](https://itunes.apple.com/us/app/flow-web-browser-downloader/id705536564?mt=8)
[Balance - Checkbook App](https://itunes.apple.com/US/app/id854362248)

If you're using this control, I'd love hearing from you!
		   DESC

  s.homepage     = "https://github.com/rolandleth/LTHPasscodeViewController"
  s.screenshots  = "https://camo.githubusercontent.com/f75ef08e3af272400ca2ce74b90b2d2ecd099d1d/687474703a2f2f726f6c616e646c6574682e636f6d2f6173736574732f696f73372d7374796c652d70617373636f64652f73637265656e73686f742e706e67", "https://camo.githubusercontent.com/4c2344eee8a3fd31e794be5e18be5fc073998915/687474703a2f2f726f6c616e646c6574682e636f6d2f6173736574732f696f73372d7374796c652d70617373636f64652f6368616e67652d70617373636f64652d73637265656e73686f742e706e67"


  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author       = { "Roland Leth" => "roland@rolandleth.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/nguillot/LTHPasscodeViewController.git", :tag => s.version }
  s.source_files = "LTHPasscodeViewController"
  s.resources  = "Localizations/**"
  s.framework  = "UIKit", "CoreGraphics", "Security"
end
