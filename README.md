`getapk` is a small CLI program that allows you to download raw APK files from
the Google Play store by using an actual Android device in debugging mode.

The Android device **does not** need to be rooted.

The version of the APK is automatically checked and included in the generated
APK filename.

# Install
Clone this repo (or copy `get-apk.sh`) and add a function to your shell
(e.g. `~/.bash_profile` or `~/.zshrc`):

```
function getapk() {
    all_args=( "$@" )
    /path/to/get-apk.sh "${all_args[@]}"
}
```

# Dependencies and prerequisites
You must have:
1. `abd` installed
2. USB/wifi debugging enabled on the Android device
3. the Android device connected via USB/wifi (whichever you enabled in step 2)

# Use on a Pixel 3a
```
getapk com.some.app.id
```

# Use on something other than Pixel 3a
You will need to update the `get-apk.sh` script to set correct values for the
following variables:

```
readonly INSTALL_BUTTON_X_COORD="550" # Determined manually for Pixel 3a
readonly INSTALL_BUTTON_Y_COORD="800" # Determined manually for Pixel 3a
```

# Example output
If the APK is not yet installed on the phone:
```
$> getapk com.authy.authy
Getting APK from the Play Store with id: com.authy.authy...
Installing APK on the phone...
Opening APK's Play Store entry on the phone...done.
Tapping the Install button on the phone...done.
Waiting for APK to install on the phone..............done.
Downloading APK file(s) from the phone...
APK (1/1) downloaded to:
com.authy.authy@v24.8.1/apk/com.authy.authy@v24.8.1-playstore.apk
```

If the APK is already installed on the phone:
```
$> getapk com.authy.authy
Getting APK from the Play Store with id: com.authy.authy...
APK is already installed on the phone.
Downloading APK file(s) from the phone...
APK (1/1) downloaded to:
com.authy.authy@v24.8.1/apk/com.authy.authy@v24.8.1-playstore.apk
```

If the APK is multi-part:
```
$> getapk com.twofasapp
Getting APK from the Play Store with id: com.twofasapp...
APK is already installed on the phone.
Downloading APK file(s) from the phone...
APK (1/5) downloaded to:
com.twofasapp@v3.8.0/apk/com.twofasapp@v3.8.0-playstore.apk
APK (2/5) downloaded to:
com.twofasapp@v3.8.0/apk/com.twofasapp-arm64_v8a@3.8.0-playstore.apk
APK (3/5) downloaded to:
com.twofasapp@v3.8.0/apk/com.twofasapp-en@3.8.0-playstore.apk
APK (4/5) downloaded to:
com.twofasapp@v3.8.0/apk/com.twofasapp-es@3.8.0-playstore.apk
APK (5/5) downloaded to:
com.twofasapp@v3.8.0/apk/com.twofasapp-xxhdpi@3.8.0-playstore.apk
```

# Known issues
- The automated clicking of the `Install` button does not work 100% of the time.
  - Observed situations where it fails: app is not free, app has some
    interstitial warning about content rating, etc
