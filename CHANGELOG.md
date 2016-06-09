# 3.7.6
* Fixed the `_setupFingerPrint` method.

# 3.7.5
* Fixed the logic when TouchID disabling.

# 3.7.4
* Fixed the logout button disappearing when canceling TouchID.
* Renamed all occurrences of *navbar* with *navBar*.
* Added a macro for the previous `mainWindow` local variable, because now it's used in more than one place.

# 3.7.3
* Made `allowUnlockWithTouchID` customizable.
* Realigned indentation to 4 spaces.
* Cosmetic improvements.
* Typo fixes.

# 3.7.2
* Added README and CHANGELOG to the pod.

# 3.7.1
* Fixed number of failed attempts logic. It now checks if `numberOfFailedAttempts >= maxNumberOfFailedAttemptsAllowed` instead of `==`.

# 3.7.0
* `isSimple` is now saved in user defaults and initialized from there, instead of `NO`.

# 3.6.9
* Added all localization files inside a bundle.

# 3.6.8
* Rotation fixes (Closed [#74](https://github.com/rolandleth/LTHPasscodeViewController/issues/74) and [#102](https://github.com/rolandleth/LTHPasscodeViewController/issues/102)).
* Fixed crash related to `UIInterfaceOrientationMaskPortrait` (Closed [#129](https://github.com/rolandleth/LTHPasscodeViewController/issues/129)).

# 3.6.7
* Navigation bar fixes.
* Logout button offset fix.
* Translation updates / fixes.
* Project update and `supportedInterfaceOrientations` fix.

# 3.6.6
* Italian localization.
* Added flag for showing the `leftBarButton`.

# 3.6.5
* Reduced observe count for application notifications.

# 3.6.4
* Dutch translations.
* Animations for failed attemp.

# 3.6.3
* Moved the `_addObservers` from `init` to `viewWillAppear` (Possible fix for [#74](https://github.com/rolandleth/LTHPasscodeViewController/issues/74)).

# 3.6.2
* Hide animatingView and dismiss keyboard when using TouchID (Closed [#99](https://github.com/rolandleth/LTHPasscodeViewController/issues/99)).

# 3.6.1
* Ability to change the "Enter passcode" vertical offset.
* Ability to add an image as the view's background.

# 3.6.0
* Portugese localization.
* Posibility to subclass (Closed [#95](https://github.com/rolandleth/LTHPasscodeViewController/issues/95)).

# 3.5.0
* Czech localization.
* Passcode can be beaten by killing the app (Closed [#78](https://github.com/rolandleth/LTHPasscodeViewController/issues/78)).
* Changed some `performSelectorOnMainThread` calls to `dispatch_async`.

# 3.4.0
* Korean localization.
* Preprocessor macro to disable TouchID on simulator.

# 3.3.3
* Spanish translations corrections.

# 3.3.2
* Added a close method (Closed [#68](https://github.com/rolandleth/LTHPasscodeViewController/issues/68)).

# 3.3.1
* Fixes.

# 3.3.0
* TouchID support.

# 3.2.1
* iPad and iOS 8 layout fixes (Closed [#74](https://github.com/rolandleth/LTHPasscodeViewController/issues/74)).

# 3.2.0
* Crash when opening the app with turn off view opened (Closed [#80](https://github.com/rolandleth/LTHPasscodeViewController/issues/80)).

# 3.1.9
* Removed redundant code.

# 3.1.8
* iOS 8 fixes.

# 3.1.7
* Moved the dismissal call before calling the `passcodeWasEnteredSuccessfully` delegate method.

# 3.1.6
* Opening lock screen in landscape (Closed [#72](https://github.com/rolandleth/LTHPasscodeViewController/issues/72)).

# 3.1.5
* Fixed a bug where keyboard did not appear on iOS6.

# 3.1.4
* View frame now takes into account status bar visibility. Nothing major or visible, it was just 20px shorter at the bottom, under the keyboard.

# 3.1.3
* Fixed a localization problem with enter new passcode.

# 3.1.2
* Fixed a bug where closing the app reset the failed attempts counter.
* Improved failed attempts logic: it now doesn’t reset unless when password is entered successfully, or app is killed.
* Removed deprecated methods.

# 3.1.1
Pushing the view wasn't handling rotation.

# 3.1.0
New customizable strings:
> * enterOldPasscodeString - The string displayed when changing the passcode.
* enterPasscodeString - The string displayed when asking for the passcode.
* enablePasscodeString - The title displayed when enabling the passcode.
* changePasscodeString - The title displayed when changing the passcode.
* turnOffPasscodeString - The title displayed when disabling the passcode.
* enterNewPasscodeString - The string displayed when asking for a new passcode.
* reenterPasscodeString - The string displayed when asking for the passcode confirmation (enabling).
* reenterNewPasscodeString - The string displayed when asking for the passcode confirmation (changing)

# 3.0.2
Renamed `SFHFKeychainUtils` to `LTHKeychainUtils` due to the possibility of conflicts with a version already present in the project. `LTHKeychainUtils` differs from the original library only by being ARC-compliant, so all the rights and thanks go to the original author, [Buzz Anders](https://github.com/ldandersen).

# 3.0.1
* Added `+deletePasscodeAndClose`.
* Improved doc a bit.

# 3.0.0

* Transformed all macros and constants into public properties. They were created before turning the control into a pod and the idea was to ease the init, but since I created the pod I never realized they get overwritten when updating.
* Now supports pushing the controller.
* Now supports saving and reading the passcode and timers in a custom location other than the Keychain. New delegate methods to handle this.
* A more comprehensive documentation.

Please swap the deprecated methods with the suggested ones; I will remove them in the next release.

#### Thanks to everyone for the help and all the suggestions that found their way into this library!