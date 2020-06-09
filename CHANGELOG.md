# 4.0.2
* Minor change: remove no needed code related to unsupported iOS versions (iOS < 7).

# 4.0.1
* Made `isCurrentlyOnScreen` public.

# 4.0.0
* Minimum deployment target increased to `10.3`.
* Removed iOS 8 specific code.
* Code style improvements.
* Misc demo project improvements.

# 3.9.4
* Avoid a crash in iOS 13 accessing the first object of the windows.

# 3.9.3
* Fixed a crash in demo project.
* Removed unused string.

# 3.9.1
* Fixed navigation bar layout when present passcode with logout enabled in iOS11.

# 3.9.0
* Replaced all Touch ID occurrences with Biometrics. On Touch ID-only devices, it has the same functionality, on Face ID-capable devices, it will use Face ID.

# 3.8.10
* Added new method to reset passcode `- (void)resetPasscode`, useful when using app extensions.

# 3.8.9
* Added support for iOS App Extensions: defining `LTH_IS_APP_EXTENSION` for an extension target will fix `LTHPasscodeViewController` crashing.
* Added new method: `- (void)showLockScreenOver:(UIView *)superview withAnimation:(BOOL)animated withLogout:(BOOL)hasLogout andLogoutTitle:(NSString *)logoutTitle`. Used to provide a view in which the lock is going to be presented, sized to and centered in.

# 3.8.8
* Fixed translations.

# 3.8.7
* Fixed subclassing by changing `LTHPasscodeViewControllerStrings` macro to use `[LTHPasscodeViewController class]` instead of `[self class]`.

# 3.8.6
* German translations fixed.

# 3.8.5
* Fixed the lock being sometimes disabled when setting the date in the past (Closed [^174](https://github.com/rolandleth/LTHPasscodeViewController/issues/174)).

# 3.8.4
* Fixed not being able to show the keyboard again after dismissing it on iPad (Closed [^171](https://github.com/rolandleth/LTHPasscodeViewController/issues/171)).

# 3.8.3
* Added a check that the new passcode is different than the existing one (Closed [^170](https://github.com/rolandleth/LTHPasscodeViewController/issues/170)).
* Improved the handling of `isSimple`.

# 3.8.2
* Fixed the usage of `self.viewLoaded` to `self.isViewLoaded` (Closed [^168](https://github.com/rolandleth/LTHPasscodeViewController/issues/168)).

# 3.8.1
* Fixed title for lockscreen with navbar (Closed [^165](https://github.com/rolandleth/LTHPasscodeViewController/issues/165)).

# 3.8.0
* Replaced all instances of `keyWindow` with `LTHMainWindow` (macro that expands `[UIApplication sharedApplication].windows[0]` - explanation in [^164](https://github.com/rolandleth/LTHPasscodeViewController/issues/164).
* Fixed a bug where the UI would not be visible (Closed [^163](https://github.com/rolandleth/LTHPasscodeViewController/issues/163)).
* Made simple passcode configurable (Closed [^157](https://github.com/rolandleth/LTHPasscodeViewController/issues/157)).
* Added a description label, placed below the passcode, to possibly explain the use of the passcode.
* New properties:
	* `digitsCount`: the number of digits for the simple passcode, between 4 and 10; can only be changed while there is no passcode active
	* `enterPasscodeInfoString`: the text used for the description label
	* `displayAdditionalInfoDuringSettingPasscode`: the flag that determines whether to show the description text or not

# 3.7.10
* New delegate method: `passcodeWasEnabled`. Called when the passcode was enabled (Closed [^156](https://github.com/rolandleth/LTHPasscodeViewController/issues/156)).
* New method: `enablePasscodeWhenApplicationEntersBackground`. It reverts what `disablePasscodeWhenApplicationEntersBackground` does: it adds observers for `UIApplicationDidEnterBackgroundNotification` and `UIApplicationWillEnterForegroundNotification` (Closed [^158](https://github.com/rolandleth/LTHPasscodeViewController/issues/158)).

# 3.7.9
* Keychain leaks fixed.
* Back button fixed, it now properly resets state.

# 3.7.8
* Improved keyboard handling when displaying the lockscreen for the first time with TouchID enabled.
* Fixed the bug where the keyboard was invisible after canceling the TouchID alert.

# 3.7.7
* Simplified Chinese improved.

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
* Rotation fixes (Closed [^74](https://github.com/rolandleth/LTHPasscodeViewController/issues/74) and [^102](https://github.com/rolandleth/LTHPasscodeViewController/issues/102)).
* Fixed crash related to `UIInterfaceOrientationMaskPortrait` (Closed [^129](https://github.com/rolandleth/LTHPasscodeViewController/issues/129)).

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
* Moved the `_addObservers` from `init` to `viewWillAppear` (Possible fix for [^74](https://github.com/rolandleth/LTHPasscodeViewController/issues/74)).

# 3.6.2
* Hide animatingView and dismiss keyboard when using TouchID (Closed [^99](https://github.com/rolandleth/LTHPasscodeViewController/issues/99)).

# 3.6.1
* Ability to change the "Enter passcode" vertical offset.
* Ability to add an image as the view's background.

# 3.6.0
* Portugese localization.
* Posibility to subclass (Closed [^95](https://github.com/rolandleth/LTHPasscodeViewController/issues/95)).

# 3.5.0
* Czech localization.
* Passcode can be beaten by killing the app (Closed [^78](https://github.com/rolandleth/LTHPasscodeViewController/issues/78)).
* Changed some `performSelectorOnMainThread` calls to `dispatch_async`.

# 3.4.0
* Korean localization.
* Preprocessor macro to disable TouchID on simulator.

# 3.3.3
* Spanish translations corrections.

# 3.3.2
* Added a close method (Closed [^68](https://github.com/rolandleth/LTHPasscodeViewController/issues/68)).

# 3.3.1
* Fixes.

# 3.3.0
* TouchID support.

# 3.2.1
* iPad and iOS 8 layout fixes (Closed [^74](https://github.com/rolandleth/LTHPasscodeViewController/issues/74)).

# 3.2.0
* Crash when opening the app with turn off view opened (Closed [^80](https://github.com/rolandleth/LTHPasscodeViewController/issues/80)).

# 3.1.9
* Removed redundant code.

# 3.1.8
* iOS 8 fixes.

# 3.1.7
* Moved the dismissal call before calling the `passcodeWasEnteredSuccessfully` delegate method.

# 3.1.6
* Opening lock screen in landscape (Closed [^72](https://github.com/rolandleth/LTHPasscodeViewController/issues/72)).

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
Renamed `SFHFKeychainUtils` to `LTHKeychainUtils` due to the possibility of conflicts with a version already present in the project. `LTHKeychainUtils` differs from the original library only by being ARC-compliant, so all the rights and thanks go to the original author, [Buzz Anders][1].

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

[1]:	https://github.com/ldandersen