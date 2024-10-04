#!/bin/bash
#set -x

#########################################################################################
# Script Information
#########################################################################################
#
#
# Name:     sdarum.sh
# Version:  0.06 (born on 2024-05-08)
# Repo:     https://github.com/theahadub/sDrum
#
# Bash using Swift Dialog created by @bartreardon
# https://github.com/swiftDialog/swiftDialog
#
# Parsed with jq by Stephen Dolan
# https://github.com/jqlang  (they are looking for help maintaining)
#
# This script was inspired by 
#   Martin Piron's: https://github.com/ooftee/Dialog-StarterKit
#   John Mahlman's Adobe-Rum with progress: https://github.com/jmahlman/Mac-Admin-Scripts
#   Dan Snelson's Setup Your Mac via swiftDialog https://snelson.us/sym
#       and https://snelson.us/2024/02/inventory-update-progress/ 
#   Trevor Sysock aka @BigMacAdmin on Slack
#       https://github.com/SecondSonConsulting/swiftDialogExamples/blob/main/checklistJSONexample.sh
#
# Based on these documents, rules, and limitations (May 14, 2024)
#   Adobe RUM Rules and limitations: https://helpx.adobe.com/enterprise/using/using-remote-update-manager.html
#   Adobe SAP Code list: https://helpx.adobe.com/enterprise/package/help/apps-deployed-without-their-base-versions.html
#   Adobe Uninstaller: https://helpx.adobe.com/enterprise/using/uninstall-creative-cloud-products.html
#
#########################################################################################
# General Information
#########################################################################################
#
# This script will use Adobe's Remote Update Manager (RUM) to update the Adobe apps
# This should improve on the gui feedback since each app can take 5-20 minutes to update
#   leaving the end user wondering if it is working or locked up.
#
# This will lets users select which apps they want updated or not.
#
# RUM will only update installed Adobe apps and does not upgrade the app so 11.0.1 to 11.1
#     and not 11.1 to 12.1
# The app just has to be installed and does not need to be signed in so this can run after 
#     the 1st install before the user logs into Creative Cloud.
# RUM polls Adobe Update server or the local Adobe Update Server if set up using the 
#     Adobe Update Server Setup Tool (AUSST). RUM deploys the latest updates available on 
#     update server to each client machine on which it is run.

#########################################################################################
# Assumptions
#########################################################################################
# You already have Dialog and JQ installed - installers to be added later
# UPDATE: jq now part of macOS 15.  We check for it in /usr/bin/jq to make sure.
# You have icons in the /Library/Management/sdrum/Branding/Icons folder that match the
#     SAP code for the product. Example: PPRO.png for Premier Pro
#
# Place the sDrum.png icon in "/Library/Management/sdrum/Branding/Icons/sDrum.png",
# 
#########################################
# Future ideas
#########################################
#     use the unistaller to list out currently installed software and their version numbers
#       challenge is to sync up the version when 2 versions are installed 
#    
#
#########################################################################################


#########################################################################################
# VARIABLES TO EDIT
#########################################################################################
logPath="/Library/Management/sdrum/"
rumlog="$logPath/AdobeRUMUpdatesLog.log" # mmmmmm, rum log
rumlog4="$logPath/AdobeRUMUpdatesLog4.log" # mmmmmm, never to much rum log
installedlog4="$logPath/AdobeInstalledAppsLog4.log" # thats not rum log
joinedlog="$logPath/joinedAppsLog.log" # thats not rum either log
rum="/usr/local/bin/RemoteUpdateManager"
adobeUninst="/usr/local/bin/AdobeUninstaller"

# Dialog Icon
icon="/System/Library/CoreServices/KeyboardSetupAssistant.app/Contents/Resources/AppIcon.icns"
# icon="https://ics.services.jamfcloud.com/icon/hash_ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9"
overlay=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )
warnIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns"
alertIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"

# Future use - detect if laptop needs to be plugged in
if system_profiler SPPowerDataType | grep -q "Battery Power" ; then
  compType="laptop"
  batteryCharge=$(system_profiler SPPowerDataType | grep "State of Charge")
  pluggedIn=$(system_profiler SPPowerDataType | grep "Connected")
  else
  compType="desktop"
fi

# swiftDialog Binary & Logs 
swiftDialogMinimumRequiredVersion="2.4.0.4750"

# Apps to install (format is FriendlyName,Location,JamfTrigger&IconName)
# rum $2 = code, $3 = update version, $2 int($3) is code+base
$rum --action=list | grep -i "mac" | awk -F'[(/]' '{print $2 int($3) "," $2 ","int($3) ".0," $3}'|sort > "$rumlog4"

# Get currently installed apps, SAP code, and current version
#                                     $2= code, $3=Base Ver, $4= Ver, $1=Friendly Name
$adobeUninst --list | awk -F' {2,}' '{print $2 int($3) "," $2 "," $3 "," $4"," $1}'| grep '^[^0,|SapCode]' | sort  > "$installedlog4"

# Results in Code(base),Code, ver, current version, Friendly Name, update version
join -a 2 -t , -j1 "$installedlog4" "$rumlog4" > $joinedlog
# makes 1CodeBase,2Code,3Base,4CurVer,5FriendlyName,6Code,7Base,8UpVer

# Results in Code(base),Code, base,ver, current version, Friendly Name, update version
APPS=$(cat "$joinedlog" | awk -F ',' '{if(NF==4) {print $1 "_update_to_" $4 "," $2 "," $3} else {print $5 "_update_from_" $4 "_to_" $8 "," $2 "," $3} }' )

# turn string in APPS into array
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
APPS=($APPS) # split the `names` string into an array by the same name
IFS=$SAVEIFS   # Restore original IFS

# swiftDialog message (Update icon with path to your company logo, title and message can be edited too)
  START_JSON='{
    "title" : "Updating Adobe",
    "message" : "Please select the apps you want to update.\n\nScoll down to see them all.\n\nThe Adobe app ***cannot*** be running during the update or the update will fail.",
    "messagefont" : "colour=#666666,weight=medium,size=12",
    "height" : "600",
    "position" : "centre",
    "moveable" : "true",
    "icon" : "/Library/Management/sdrum/Branding/Icons/sDrum.png",
    "button1text" : "OK",
    "button2text" : "Cancel",
    "checkboxstyle": {
      "style": "switch",
      "size": "small"
    }
  }'
  
  INSTALL_JSON='{
    "title" : "Updating Adobe",
    "message" : "Please wait while we update the selected apps:",
    "messagefont" : "colour=#666666,weight=medium,size=12",
    "icon" : "/Library/Management/sdrum/Branding/Icons/sDrum.png",
    "overlayicon" : "SF=arrow.down.circle.fill,palette=white,black,none,bgcolor=none",
    "position" : "centre",
    "moveable" : "true",
    "button1text" : "Please wait"
  }'

#########################################################################################
# SCRIPT VARIABLES
#########################################################################################

# # location of dialog and dialog command file
 DIALOG_APP="/usr/local/bin/dialog"
 DIALOG_COMMAND_FILE="/var/tmp/dialog.log"
 START_JSON_FILE="/var/tmp/dialog_START_JSON.json"
 INSTALL_JSON_FILE="/var/tmp/dialog_INSTALL_JSON.json"
 CHECKED_JSON_FILE="/var/tmp/dialog_CHECKED_JSON.json"

# set progress total to the number of apps in the list
  PROGRESS_TOTAL=${#APPS[@]}

# Jamf binary
  JAMF="/usr/local/bin/jamf"

# Dependencies Triggers
  DIALOG_TRIGGER="install_swiftdialog"
  JQ_TRIGGER="install_jq"

#########################################################################################
# Logging
#########################################################################################

# Enable logging to a file on disk and specify a directory
  ENABLE_LOGFILE="true" # false (default) or true to write the logs to a file
  LOGDIR="/Library/Management/sdrum/Logs" # /var/tmp (default) or override by specifying a path

#########################################################################################
# Global Functions
#########################################################################################
# Logging:  info, warn, error, fatal (exits 1 or pass in an exit code after msg)
# Init:     sets up logging and welcome text
# Cleanup:  trap function to clean up and print finish text (modify as required)

echoerr() { printf "%s\n" "$*" >&2 ; }
echolog() { if [[ "${ENABLE_LOGFILE}" == "true" ]]; then printf "%s %s\n" "$(date +"%F %R:%S")" "$*" >>"${LOGFILE}"; fi }
info()    { echoerr "[INFO ] $*" ; echolog "[INFO ]  $*" ; }
warn()    { echoerr "[WARN ] $*" ; echolog "[WARN ]  $*" ; }
error()   { echoerr "[ERROR] $*" ; echolog "[ERROR]  $*" ; }
fatal()   { echoerr "[FATAL] $*" ; echolog "[FATAL]  $*" ; exit "${2:-1}" ; }

SCRIPT_NAME=$(basename "${0}") # Not inline in case ZHS
_init () {
  # Setup log file if enabled
  if [[ "${ENABLE_LOGFILE}" == "true" ]]; then
    LOGFILE="${LOGDIR:-/var/tmp}/$(date +"%F_%H.%M.%S")-${SCRIPT_NAME}.log"
    [[ -n ${LOGDIR} && ! -d ${LOGDIR} ]] && mkdir -p "${LOGDIR}"
    [[ ! -f ${LOGFILE} ]] && touch "${LOGFILE}"
  fi
  
  info "## Script: ${SCRIPT_NAME}"
  info "## Start : $(date +"%F %R:%S")"
}

cleanup() {
  EXIT_CODE=$?
  # Create this function to perform clean up at exit
  # exit_cleanup "${EXIT_CODE}" # implement as required
  info "## Finish: $(date +"%F %R:%S")"
  info "## Exit Code: ${EXIT_CODE}"
}

# Global Function Setup
  trap cleanup EXIT
  _init

###################
# Dialog functions
###################

function dialogInstall() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    preFlight "Installing swiftDialog..."

    # Create temporary working directory
    workDirectory=$( /usr/bin/basename "$0" )
    tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

    # Verify the download
    teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

        /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
        sleep 2
        dialogVersion=$( /usr/local/bin/dialog --version )
        preFlight "swiftDialog version ${dialogVersion} installed; proceeding..."

    else

        # Display a so-called "simple" dialog if Team ID fails to validate
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
        completionActionOption="Quit"
        exitCode="1"
        quitScript

    fi

    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"

}

function dialogCheck() {

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        preFlight "swiftDialog not found. Installing..."
        dialogInstall

    else

        dialogVersion=$(/usr/local/bin/dialog --version)
        if [[ "${dialogVersion}" < "${swiftDialogMinimumRequiredVersion}" ]]; then
            
            preFlight "swiftDialog version ${dialogVersion} found but swiftDialog ${swiftDialogMinimumRequiredVersion} or newer is required; updating..."
            dialogInstall
            
        else

        preFlight "swiftDialog version ${dialogVersion} found; proceeding..."

        fi
    
    fi

}

#########################################################################################
# Script Functions
#########################################################################################

dialog_command() {
  echo "$1"
  echo "$1"  >> "${DIALOG_COMMAND_FILE}"
  echo "315 debug 1 $1"
}

finalise(){
  dialog_command "overlayicon: SF=checkmark.circle.fill,palette=white,black,none,bgcolor=none"
  dialog_command "progress: complete"
  dialog_command "button1text: Done"
  dialog_command "button1: enable" 
}

#########################################################################################
# Kill a specified process
#########################################################################################

function killProcess() {

    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        info "Attempting to terminate the '$process' process …"
        info "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            errorOut "'$process' could not be terminated."
        fi
    else
        info "The '$process' process isn't running."
    fi

}

#########################################################################################
# Main Script
#########################################################################################

# Quit Self Service after starting - too distracting
killProcess "Self Service"

# check for power
# if [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
#   echo "power on!"
# fi

# Install swiftDialog if not installed
  if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
    warn "swiftDialog missing, installing"
    dialogCheck
  else
    info "swiftDialog already installed"
  fi

# Install jq if not installed
  if [[ ! -e "/usr/local/bin/jq" ]]; then
    warn "JQ missing, installing"
#    "${JAMF}" "policy" -event "${JQ_TRIGGER}"
    "${DIALOG_APP}"  --title none --icon warning --iconsize 80 --message "### JQ Missing  \n\nThis script will not run with out JQ installed" --messagealignment centre --buttonstyle centre --centreicon --width 300 --height 300
    fatal "JQ Missing"
  else
    info "JQ already installed"
  fi

# Install rum if not installed
  if [[ ! -e "/usr/local/bin/RemoteUpdateManager" ]]; then
    warn "RUM missing, installing"
#    "${JAMF}" "policy" -event "${RUM_TRIGGER}"
    "${DIALOG_APP}"  --title none --icon warning --iconsize 80 --message "### The Rum Missing  \n\nThis script will not run with out Rum installed" --messagealignment centre --buttonstyle centre --centreicon --width 300 --height 300
    fatal "The Rum is Missing"
  else
    info "RUM already installed"
  fi

#  Ensure computer does not go to sleep during updates
symPID="$$"
info "PRE-FLIGHT CHECK: Caffeinating this script (PID: $symPID)"
caffeinate -dimsu -w $symPID &

# Create icons folder and download them
  if [[ ! -e "/Library/Management/sdrum/Branding/Icons/" ]]; then
    info "Creating Icons folder"
    mkdir -p "/Library/Management/sdrum/Branding/Icons/"
  else
    info "Icons folder already exists"
  fi
  
  # Results in 1:Code(base), 2:Code, 3:base, 4:ver, 5:current version, 6:Friendly Name, 7:update version

  for APP in "${APPS[@]}"; do
    APP_FNAME=$(echo "$APP" | cut -d ',' -f1)
        echo "395 debug app-fname = $APP_FNAME"
    APP_TRIGGER=$(echo "$APP" | cut -d ',' -f2)
        echo "397 debug app-trigger = $APP_TRIGGER"
    if [[ ! -e "/Library/Management/sdrum/Branding/Icons/${APP_TRIGGER}.png" ]]; then
      warn "${APP_FNAME} icon not found"
#      curl "${BUCKET}${APP_TRIGGER}.png" -o "/Library/Management/sdrum/Branding/Icons/${APP_TRIGGER}.png"
        cp /Library/Management/sdrum/Branding/Icons/CreativeCloudApp.png /Library/Management/sdrum/Branding/Icons/${APP_TRIGGER}.png
    elif [[ -e "/Library/Management/sdrum/Branding/Icons/${APP_TRIGGER}.png" ]]; then
      info "${APP_FNAME} icon already cached"
    fi
  done

# Create the list of apps and format it in json
  CHECKBOX_JSON=$(
    printf '%s\n' "${APPS[@]}" | \
    awk -F ',' '{printf "{\"label\":\"%s\",\"checked\":true,\"icon\":\"/Library/Management/sdrum/Branding/Icons/%s.png\"}\n", $1, $2}' | \
    jq -s '{"checkbox": .}'
    )
  
  LISTITEMS_JSON=$(
    printf '%s\n' "${APPS[@]}" | \
    awk -F ',' '{printf "{\"title\":\"%s\",\"icon\":\"/Library/Management/sdrum/Branding/Icons/%s.png\",\"status\":\"pending\",\"statustext\":\"Pending\"}\n", $1, $2}' | \
    jq -s '{"listitem": .}'
    )

# Merge json variables into one file
  START_MERGED_JSON=$(jq -n --argjson START_JSON "${START_JSON}" --argjson CHECKBOX_JSON "${CHECKBOX_JSON}" '$START_JSON + $CHECKBOX_JSON')
  echo "${START_MERGED_JSON}" > "${START_JSON_FILE}"
  
  INSTALL_MERGED_JSON=$(jq -n --argjson INSTALL_JSON "${INSTALL_JSON}" --argjson LISTITEMS_JSON "${LISTITEMS_JSON}" '$INSTALL_JSON + $LISTITEMS_JSON') 
  echo "${INSTALL_MERGED_JSON}" > "${INSTALL_JSON_FILE}"

# Launch Dialog and display the list of apps available to install
  DIALOG_CMD="${DIALOG_APP} 
  --jsonfile ${START_JSON_FILE} \
  --json"

  info "Launching Dialog - App Select"
  APPS_SELECTED=$($DIALOG_CMD)

# Exit if user clicked cancel (array is empty)
  if [[ ! "${APPS_SELECTED[*]}" ]]; then
    killProcess "caffeinate"
    fatal "User clicked cancel."
  fi

# Read the JSON object and construct an array of key-value pairs
  APPS_SELECTED_values=()
  while IFS= read -r line; do
    APPS_SELECTED_values+=("$line")
  done < <(echo "${APPS_SELECTED}" | jq -r 'to_entries | map("\(.key)=\(.value)")[]')

#######################
# Create array with all the apps to install
#######################
  INSTALL_IS_TRUE=()

  # Results in 1:Code(base), 2:Code, 3:base, 4:ver, 5:current version, 6:Friendly Name, 7:update version
  for APP in "${APPS_SELECTED_values[@]}"; do
    APP_FNAME=$(echo "${APP}" | cut -d '=' -f1)
        echo "455 debug app-fname = $APP_FNAME"
    VALUE=$(echo "${APP}" | cut -d '=' -f2)
    if [[ "${VALUE}" == "true" ]]; then
      info "${APP_FNAME} will be installed"
      INSTALL_IS_TRUE+=("${APP_FNAME}")
    elif [[ "${VALUE}" == "false" ]]; then
      info "${APP_FNAME} will be skipped"
      # Update the status and statustext of skipped apps in the JSON file
      /usr/local/bin/jq --arg app "${APP_FNAME}" '.listitem |= map(if .title == $app then .status = "fail" | .statustext = "Skipping" else . end)' "${INSTALL_JSON_FILE}" > "${CHECKED_JSON_FILE}"
      # Rename the updated file back to the original one
      mv "${CHECKED_JSON_FILE}" "${INSTALL_JSON_FILE}"
    fi
  done

#######################
# Update Dialog with the install json file
#######################

  DIALOG_CMD="${DIALOG_APP} \
  --progress ${PROGRESS_TOTAL} \
  --button1disabled \
  --jsonfile $INSTALL_JSON_FILE"
  
  STEP_PROGRESS=0
  
  info "Launching Dialog - App Install"
  eval "$DIALOG_CMD" & sleep 2

#######################
# Loop thru array and install apps if they were selected
#######################

# Results in 1:Code(base), 2:Code, 3:base, 4:ver, 5:current version, 6:Friendly Name, 7:update version

  for APP in "${APPS[@]}"; do
    APP_FNAME=$(echo "${APP}" | cut -d ',' -f1)
     echo "490 debug app-fname = $APP_FNAME"
    APP_TRIGGER=$(echo "${APP}" | cut -d ',' -f2)
    # echo "debug app-trigger = $APP_TRIGGER"
    # get verion family changing 11.2.8 to 11.0 for rum
    # APP_VERSION=$(echo "${APP}" | cut -d ',' -f2 | awk -F '.' '{print $1 ".0"}')
    APP_VERSION=$(echo "${APP}" | cut -d ',' -f3)
    STEP_PROGRESS=$(( 1 + STEP_PROGRESS ))
    dialog_command "progress: ${STEP_PROGRESS}"
    STATUS=$(jq --arg app "${APP_FNAME}" '.listitem[] | select(.title == $app) | .statustext' "${INSTALL_JSON_FILE}" | tr -d '"')
     echo "499 debug status = $STATUS"
     echo "500 debug install json = $INSTALL_JSON_FILE"

    if [[ "${STATUS}" = "Pending" ]]; then
        echo "502 debug Got Status of $STATUS"
        info "${APP_FNAME} Updating"
        dialog_command "listitem: ${APP_FNAME}: wait"
        dialog_command "progresstext: Updating ${APP_FNAME}"
        info "Rum running ${APP_FNAME} with trigger ${APP_TRIGGER}"

        # Execute rum and just install the product and version family
        echo "debug 508 --productVersions=${APP_TRIGGER}#${APP_VERSION}" # debug - show results
        # syntax --productVersions=[code]#[base ver]
        $rum --action=install --productVersions=${APP_TRIGGER}#${APP_VERSION}
        # $rum --action=list  #debug, do nothing
        
        sleep 1
        # we just assume the update succeeds and move forward.
        info "${APP_FNAME} updated"
        dialog_command "listitem: ${APP_FNAME}: success"
        echo "526 debug success for $APP_FNAME"
    elif [[ "${STATUS}" = "Skipping" ]]; then
      warn "${APP_FNAME} was NOT selected by the user to be installed."
      dialog_command "progresstext: Skipping ${APP_FNAME}"
    fi
    sleep 1
  done

# Loop through failed array and report back if required
  if [[ ${#FAILED_STATUS[@]} -eq 0 ]] ; then
    info "All apps installed."
    dialog_command "progresstext: All done!"
  else
    error "Failed: ${FAILED_STATUS[*]}"
    dialog_command "progresstext: Some installations have failed..."
  fi

# Finishing up
killProcess "caffeinate"
  finalise

  exit 0
