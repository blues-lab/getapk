`getapk` is a small CLI program that allows you to download raw APK files from
the Google Play store by using an actual Android device in debugging mode.

The Android device **does not** need to be rooted.

The version of the APK is automatically checked and included in the generated
APK filename.

# Install
Clone this repo (or copy `get-apk.sh`) and add this to your `~/.bash_profile`:

```
function getapk() {
    apk_id=$1
    /path/to/get-apk.sh ${apk_id}
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
Getting apk from the Play Store with id: com.authy.authy...
Installing APK...
Opening APK's Play Store entry on the phone...done.
Tapping the Install button on the phone...done.
Waiting for APK to install on the phone........done.
Downloading apk from the phone...done.
APK downloaded to: com.authy.authy@v24.8.1/apk/com.authy.authy@v24.8.1-playstore.apk
```

If the APK is already installed on the phone:
```
$> getapk com.authy.authy
Getting apk from the Play Store with id: com.authy.authy...
APK is already installed on the phone.
Downloading apk from the phone...done.
APK downloaded to: com.authy.authy@v24.8.1/apk/com.authy.authy@v24.8.1-playstore.apk
```

If the APK is multi-part:
```
$> getapk com.twofasapp
Getting apk from the Play Store with id: com.twofasapp...
APK is already installed on the phone.
Downloading apk from the phone...
===== WARNING =====
Multi-part apk detected!

package:/data/app/com.twofasapp-c_EDsgL6BSRr1v3x8bFZNg==/base.apk
package:/data/app/com.twofasapp-c_EDsgL6BSRr1v3x8bFZNg==/split_config.arm64_v8a.apk
package:/data/app/com.twofasapp-c_EDsgL6BSRr1v3x8bFZNg==/split_config.en.apk
package:/data/app/com.twofasapp-c_EDsgL6BSRr1v3x8bFZNg==/split_config.es.apk
package:/data/app/com.twofasapp-c_EDsgL6BSRr1v3x8bFZNg==/split_config.xxhdpi.apk

Downloading ONLY the base.apk
===== WARNING =====
done.
APK downloaded to: com.twofasapp@v3.8.0/apk/com.twofasapp@v3.8.0-playstore.apk
```

# Known issues
- The automated clicking of the `Install` button does not work 100% of the time.
  - Observed situations where it fails: app is not free, app has some
    interstitial warning about content rating, etc
