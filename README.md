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

# Known issues
- The automated clicking of the `Install` button does not work 100% of the time.
  - Observed situations where it fails: app is not free, app has some interstitial warning about content rating, etc
