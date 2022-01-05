#!/bin/sh
# shellcheck disable=SC3010

# Exit the script if any commands error (return non-zero status code).
# set -e

# Print all commands before running them
# set -x

##
# Global variables and constants.
##
readonly apk_id="$1"

# Useful docs: https://www.youtube.com/watch?v=PqgDvAAaTgA
readonly INSTALL_BUTTON_X_COORD="550" # Determined manually for Pixel 3a
readonly INSTALL_BUTTON_Y_COORD="800" # Determined manually for Pixel 3a

##
# Verify script arguments
##
readonly num_args="$#"
if [ ! "${num_args}" -eq 1 ]
then
    echo "Wrong number of arguments!"
    echo "Expected a single argument (the apk id), but got ${num_args} arguments."
    echo "Example usage: \$> getapk com.authy.authy"
    exit 1
fi

##
# Verify the number of Android devices available to adb
##
adb_devices_line_count=$(adb devices -l | wc -l)
device_count=$(( adb_devices_line_count - 2 ))
if [ ! "${adb_devices_line_count}" -eq 3 ]
then
    echo "Wrong number of Android devices!"
    echo "Expected a single Android device in debugging mode, but adb found ${device_count} devices."
    exit 1
fi

##
# Return "YES" if the apk is installed on the phone; "NO" otherwise.
##
is_apk_installed() {
    if [[ $(adb shell pm list packages | grep "${apk_id}") ]]
    then
        echo "YES"
    else
        echo "NO"
    fi
}

##
# Install the APK from the Google Play Store onto the phone.
##
install_apk() {
    ##
    # Open Google Play app to the entry for the given APK id
    #
    # Useful docs: https://stackoverflow.com/questions/53157208/automated-installation-of-an-apk-from-the-google-play-store
    ##
    printf "Opening APK's Play Store entry on the phone..."
    adb shell "am start -a android.intent.action.VIEW -d market://details?id=${apk_id}" > /dev/null
    sleep 1
    printf "done.\n"

    ##
    # Tap the 'Install' button
    ##
    printf "Tapping the Install button on the phone..."
    adb shell input tap ${INSTALL_BUTTON_X_COORD} ${INSTALL_BUTTON_Y_COORD}
    printf "done.\n"

    ##
    # Wait for the app to be installed...
    ##
    printf "Waiting for APK to install on the phone..."
    until [[ $(is_apk_installed) = "YES" ]]
    # Useful docs explaining double brackets: https://stackoverflow.com/a/3870055
    do
        printf "."
        sleep 0.5
    done
    printf "done.\n"
}

##
# Copy the APK from the phone to the laptop.
#
# Useful docs: https://stackoverflow.com/questions/4032960/how-do-i-get-an-apk-file-from-an-android-device
##
download_apk() {
    is_multipart_apk="NO"

    printf "Downloading apk from the phone..."

    # Check for multi-part APKs
    remote_apk_path_line_count=$(adb shell pm path "${apk_id}" | wc -l)
    readonly remote_apk_path_line_count
    # printf "\n remote_apk_path_line_count = ${remote_apk_path_line_count}"

    if [[ ! ${remote_apk_path_line_count} -eq 1 ]]
    then
        is_multipart_apk="YES"

        # Sadly, this horrible formatting is required to prevent whitespace from
        # getting printed in the output.
        printf "\n===== WARNING =====
Multi-part apk detected!\n
%s \n
Downloading ONLY the base.apk
===== WARNING =====\n" "$(adb shell pm path "${apk_id}")"
    fi

    # Get all paths, keep only the first, and then split on ":" and return the
    # left hand side
    remote_apk_path=$(adb shell pm path "${apk_id}" | head -n 1 | awk -F':' '{print $2}')
    readonly remote_apk_path
    # echo "remote_apk_path = ${remote_apk_path}"

    # Get APK package information, grep the versionName, split on '=', and
    # return the left hand value (the apk version).
    apk_version=$(adb shell dumpsys package "${apk_id}" | grep versionName | awk -F'=' '{print $2}')
    readonly apk_version
    readonly apk_versioned_name_base="${apk_id}@v${apk_version}"

    # Make the output directory in which to save the APK and checksum
    readonly output_dir="${apk_versioned_name_base}/apk"
    mkdir -p "${output_dir}"
    readonly local_apk_path="${output_dir}/${apk_versioned_name_base}-playstore.apk"

    # Copy the APK from the phone to the laptop
    adb pull "${remote_apk_path}" "${local_apk_path}" > /dev/null
    printf "done.\n"
    echo "APK downloaded to: ${local_apk_path}"

    # If multipart, record the warning message in a text file
    if [[ ${is_multipart_apk} = "YES" ]]
    then
        # Sadly, this horrible formatting is required to prevent whitespace from
        # getting printed in the output.
                printf "\n===== WARNING =====
Multi-part apk detected!\n
%s \n
Downloading ONLY the base.apk
===== WARNING =====\n" "$(adb shell pm path "${apk_id}")" > "${output_dir}/multipart.getapk.txt"
    fi

    # Record the sha256 checksum of the downloaded APK
    shasum --algorithm 256 --binary "${local_apk_path}" > "${local_apk_path}.sha256"
}

main() {
    echo "Getting apk from the Play Store with id: $apk_id..."

    if [[ $(is_apk_installed) = "YES" ]]
    then
        echo "APK is already installed on the phone."
    else
        echo "Installing APK on the phone..."
        install_apk
    fi

    download_apk
}

main
