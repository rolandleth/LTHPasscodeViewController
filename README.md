# LTHPasscodeViewController
Simple to use iOS 7 style (replica, if you will) Passcode view.

# How to use
Drag the contents of `AddToYourProject` to your project.

* `initForTurningPasscodeOff` and `initForChangingPasscode` are displayed as modal views, since they will most likely be called from the Settings. 
* `initForBeingDisplayedAsLockscreen` is displayed with a slide down animation, which combined with the keyboard sliding up animation creates a "locking" impression.
* `passcodeExistsInKeychain` checks if a passcode exists in the Keychain.

Everything is easily customisable with macros and static constants.

Makes use of [SFHFKeyChainUtils](https://github.com/ldandersen/scifihifi-iphone) to save the passcode in the Keychain. I know he dropped support for it, but I updated it to ARC 2 years ago ([with help](http://stackoverflow.com/questions/7663443/sfhfkeychainutils-ios-keychain-arc-compatible)) and I kept using it since. The 'new' version isn't updated to ARC anyway, so I saw no reason to switch to it.

Rather than writing a big documentation, I heavily commented it as best as I could. Feel free to [contact me](mailto:roland@rolandleth.com), or open an issue if anything is unclear, bugged, or can be improved.

# License
Licensed under MIT.