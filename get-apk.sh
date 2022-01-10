#!/bin/sh
# shellcheck disable=SC3010

# Exit the script if any commands error (return non-zero status code).
# set -e

# Print all commands before running them
# set -x

##
# Global variables and constants.
##
readonly is_debugging_enabled="NO"

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
    echo "Expected a single argument (the APK id), but got ${num_args} arguments."
    echo "Example usage: \$> getapk com.authy.authy"
    exit 1
fi

##
# Verify the number of Android devices available to adb
##
adb_devices_line_count=$(adb devices -l | wc -l)
device_count=$(( adb_devices_line_count - 2 ))
if [ ! "${device_count}" -eq 1 ]
then
    echo "Wrong number of Android devices!"
    echo "Expected a single Android device in debugging mode, but adb found ${device_count} devices."
    exit 1
fi

##
# Debugging echo
##
debug_println() {
    if [[ "${is_debugging_enabled}" = "YES" ]]; then
        printf "[DEBUG] %s\n" "$1"
    fi
}

##
# Return "YES" if the APK is installed on the phone; "NO" otherwise.
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
    echo "Downloading APK file(s) from the phone..."

    remote_apk_paths=$(adb shell pm path "${apk_id}")
    readonly remote_apk_paths
    debug_println "remote_apk_paths = ${remote_apk_paths}"

    # The xargs is there to trim the whitespace from the line count
    path_count=$(echo "${remote_apk_paths}" | wc -l | xargs)
    readonly path_count
    debug_println "path_count = ${path_count}"

    if [[ ${path_count} -eq 0 ]]; then
        echo "APK with id ${apk_id} is not installed on the phone!"
    fi

    # Get APK package information, grep the versionName, split on '=', and
    # return the left hand value (the APK version).
    apk_version=$(
        adb shell dumpsys package "${apk_id}" | \
        grep versionName | \
        awk -F '=' '{print $2}'
    )
    readonly apk_version
    readonly apk_versioned_name_base="${apk_id}@v${apk_version}"

    # Make the output directory in which to save the APK(s) and checksum(s)
    readonly output_dir="${apk_versioned_name_base}/apk"
    mkdir -p "${output_dir}"

    path_number=1
    for line in ${remote_apk_paths}; do
        debug_println "Line = ${line}"

        remote_apk_path=$(echo "${line}" | awk -F ':' '{print $2}')
        debug_println "Remote APK path = ${remote_apk_path}"

        # Return everything from remote_apk_path after the final slash "/"
        remote_apk_filename="${remote_apk_path##*/}"
        debug_println "Remote APK filename = ${remote_apk_filename}"

        if [[ "${remote_apk_filename}" = "base.apk" ]]; then
            local_apk_path="${output_dir}/${apk_versioned_name_base}-playstore.apk"
        else
            # Split into an array using period delimiter and return the second index.
            # Filenames for multipart APKs look like: "split_config.en.apk"
            multipart_apk_filename_part=$(echo "${remote_apk_filename}" | awk -F '.' '{print $2}')
            debug_println "Multipart APK filename part = ${multipart_apk_filename_part}"

            local_apk_path="${output_dir}/${apk_id}-${multipart_apk_filename_part}@${apk_version}-playstore.apk"
        fi
        debug_println "Local APK path = ${local_apk_path}"

        # Copy the APK from the phone to the laptop
        adb pull "${remote_apk_path}" "${local_apk_path}" > /dev/null
        printf "APK (%s/%s) downloaded to:\n%s\n" "${path_number}" "${path_count}" "${local_apk_path}"

        # Record the sha256 checksum of the downloaded APK
        shasum --algorithm 256 --binary "${local_apk_path}" > "${local_apk_path}.sha256"

        path_number=$(( path_number + 1))
    done
}

main() {
    echo "Getting APK from the Play Store with id: $apk_id..."

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
